# Oracle AMI builder

Uses Packer and VirtualBox to install and configure a basic Amazon Machine Image for Oracle Linux.

Uploads VirtualBox image to AWS and imports it as an AMI that can be used within EC2.

* Currently supports Oracle 7.2 x86_64.
* Depends on [Packer](http://packer.io)
* Depends on [VirtualBox](http://virtualbox.org)
* Creates AMI in the AWS region you've set in ENV.
* Includes a Ruby Rake task to automate almost every step.

Somewhat inspired by Chef's [Bento](https://github.com/chef/bento).

## Features

* Single partition - grows on first boot (to assume full size of allocated storage like stock AMIs).
* Compressed size around 430MB.
* `cloud-init` for configuration and retrieval of authorized SSH keys on first boot.
* Username `ec2-user` (added to sudoers). Password locked (login via key only).
* No root SSH login, root password locked.
* No password based SSH login - keys only.
* Uses RHCK kernel, can be set to UEK on or after first boot.
* No VirtualBox cruft in the resulting image.


## First time

It's assumed you're using AWS credentials with enough access to create s3 buckets, roles, import images among other tasks.

* Configure `S3_BUCKET` AWS credentials and region in ENV or a `.env` file.

Then:

```shell
$ bundle install
$ bundle exec rake aws:setup
```

This will create the S3 Bucket and a `vmimport` IAM role with the correct policies for this bucket.

## Usage

```shell
$ bundle exec rake
```

This will:
* Run Packer to create an image.
* Upload the image to S3.
* Import the Image into EC2.


### Discrete tasks:

```shell
$ bundle exec rake -T
rake aws:create_bucket                  # Create S3 bucket
rake aws:create_role_with_trust_policy  # Create IAM Role with Trust Policy
rake aws:create_service_policy          # Add IAM Role Service Policy
rake aws:import_image                   # Import the VMDK to EC2 (create an AMI)
rake aws:import_status                  # Show AMI Import task status
rake aws:setup                          # AWS setup tasks
rake aws:upload                         # Upload VMDK to S3 bucket
rake packer:build                       # Upload VMDK to with Packer
```

### Switching kernel via instance user data

Due to EC2 import requirements the RHEL kernel is used.

Oracle's Unbreakable kernel can be used but needs to be configured for boot, you can do this via EC2 user data when launching your instance like so:

```shell
#!/bin/bash

grub2-set-default 1
grub2-mkconfig -o /boot/grub2/grub.cfg
# you must reboot for this to take effect
```
