require 'aws-sdk'
require 'dotenv/tasks'
require 'awesome_print'

namespace :packer do
  desc 'Upload VMDK to with Packer'
  task :build do
    system 'packer build --force oracle-7.1-x86_64.json'
  end
end

namespace :aws do
  desc 'Upload VMDK to S3 bucket'
  task :upload => :dotenv do
    s3 = Aws::S3::Resource.new
    puts 'Uploading VMDK'
    s3.bucket(ENV.fetch('S3_BUCKET')).object('oracle-7.1-x86_64-disk1.vmdk').upload_file('output/oracle-7.1-x86_64-disk1.vmdk')
    puts 'Upload Complete'
  end

  desc 'Import the VMDK to EC2 (create an AMI)'
  task :import_image => :dotenv do
    s3 = Aws::S3::Resource.new
    object = s3.bucket(ENV.fetch('S3_BUCKET')).object('oracle-7.1-x86_64-disk1.vmdk')
    payload = {
      dry_run: false,
      description: 'Oracle Linux 7.1 x64',
      disk_containers: [
        {
          description: 'Oracle Linux 7.1 x64',
          url: object.presigned_url(:get, expires_in: 3600),
        },
      ],
    }
    ec2 = Aws::EC2::Client.new
    puts 'Tasking AMI Import'
    ami = ec2.import_image(payload)
    ap ec2.describe_import_image_tasks(import_task_ids: [ami.import_task_id])
  end

  desc 'Show AMI Import task status'
  task :import_status => :dotenv do
    ec2 = Aws::EC2::Client.new
    ap ec2.describe_import_image_tasks
  end

  desc 'Create S3 bucket'
  task :create_bucket => :dotenv do
    s3 = Aws::S3::Client.new
    s3.create_bucket(bucket: ENV.fetch('S3_BUCKET'))
    puts 'created S3 bucket'
  end

  desc 'Create IAM Role with Trust Policy'
  task :create_role_with_trust_policy => :dotenv do
    policy = {
      'Version' => '2012-10-17',
      'Statement' => [
        {
          'Sid' => '',
          'Effect' => 'Allow',
          'Principal' => {
            'Service' => 'vmie.amazonaws.com'
          },
          'Action' => 'sts:AssumeRole',
          'Condition' => {
            'StringEquals' => {
              'sts:ExternalId' => 'vmimport'
            }
          }
        }
      ]
    }

    iam = Aws::IAM::Client.new
    iam.create_role({
      role_name: 'vmimport',
      assume_role_policy_document: policy.to_json,
    })
  end

  desc 'Add IAM Role Service Policy'
  task :create_service_policy => :dotenv do
    bucket = ENV.fetch('S3_BUCKET')
    policy = {
      'Version' => '2012-10-17',
      'Statement'=> [
        {
          'Effect' => 'Allow',
          'Action' => [
            's3:ListBucket',
            's3:GetBucketLocation'
          ],
          'Resource' => ["arn:aws:s3:::#{bucket}"]
        },
        {
          'Effect' => 'Allow',
          'Action' => ['s3:GetObject'],
          'Resource' => ["arn:aws:s3:::#{bucket}/*"]
        },
        {
          'Effect' => 'Allow',
          'Action' => [
            'ec2:ModifySnapshotAttribute',
            'ec2:CopySnapshot',
            'ec2:RegisterImage',
            'ec2:Describe*'
          ],
          'Resource' => '*'
        }
      ]
    }

    iam = Aws::IAM::Client.new
    iam.put_role_policy({
      role_name: 'vmimport',
      policy_name: 'vmimport',
      policy_document: policy.to_json,
    })
  end

  desc 'AWS setup tasks'
  task :setup do
    Rake::Task['aws:create_bucket'].invoke
    Rake::Task['aws:create_role_with_trust_policy'].invoke
    Rake::Task['aws:create_service_policy'].invoke
  end
end

task all: ['packer:build', 'aws:upload', 'aws:import_image']
