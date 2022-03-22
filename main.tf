# Creates midserver with basic configuration with the instance profile, IAM policy, role in developement account.

# IAM Role for midserver on Dev account 

resource "aws_iam_role" "midserver_trusted_role" {
 name   = "midserver_trusted_role"
 tags = merge(
  local.standard_tags
 )
 assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# IAM policy for midserver in all kabbage accounts

resource "aws_iam_policy" "midserver_trusted_policy" {

  name         = "midserver_trusted_policy"
  path         = "/"
  description  = "IAM policy for midserver_trusted_role"
  tags = merge(
    local.standard_tags
  )
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::*:role/midserver_assume_role"
    }
}
EOF
}

# midserver_trusted_policy Attachment on the midserver_trusted_role.

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role        = aws_iam_role.midserver_trusted_role.name
  policy_arn  = aws_iam_policy.midserver_trusted_policy.arn
}

# SSM_managed_policy Attachment on the midserver_trusted_role.

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role        = aws_iam_role.midserver_trusted_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# instance_profile for the MID server EC2 Instance

resource "aws_iam_instance_profile" "MID_instance_profile" {
  name = "MID_instance_profile"
  role = aws_iam_role.midserver_trusted_role.name
}

# security group for the MID server

resource "aws_security_group" "midserver_sg" {
  name        = "midserver_sg"
  description = "security group for MID Server"
  vpc_id      = "vpc-04479fd365b003a64"
  ingress {
    description      = "Open hhtps to Internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = merge(
    local.standard_tags
  )
}

# EC2 instance for MID server

resource "aws_instance" "MIDserver" {
  ami           = "ami-0b0af3577fe5e3532" # us-east-1
  instance_type = "c5.xlarge"
  tags = merge(
    local.standard_tags
  )
  subnet_id = "subnet-03161e8328131c0ad"
  availability_zone = "us-east-1a"
  iam_instance_profile = aws_iam_instance_profile.MID_instance_profile.name
  vpc_security_group_ids = [
    aws_security_group.midserver_sg.id
  ]
  user_data = <<EOF
#!/bin/bash
echo "Install Python and ssm agent"
sudo yum install python2 -y
sudo dnf install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm 
echo "Install aws cli"
sudo su -

echo "Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

EOF
}
