locals {
  my_ip        = ["xx.xxx.xx.xx/32"]
}

// create the virtual private cloud

resource "aws_vpc" "dwe-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
 
  tags = {
    Name = "tushar-vpc"
  }
}

// create the internet gateway

resource "aws_internet_gateway" "dwe-igw" {
  vpc_id = "${aws_vpc.dwe-vpc.id}"
 
  tags = {
    Name = "tushar-igw"
  }
}

// create a dedicated subnet

resource "aws_subnet" "dwe-subnet" {
  vpc_id            = "${aws_vpc.dwe-vpc.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
 
  tags = {
    Name = "tushar-subnet"
  }
}

// create routing table which points to the internet gateway

resource "aws_route_table" "dwe-route" {
  vpc_id = "${aws_vpc.dwe-vpc.id}"
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dwe-igw.id}"
  }
 
  tags = {
    Name = "Routetable-igw"
  }
}

// associate the routing table with the subnet

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.dwe-subnet.id}"
  route_table_id = "${aws_route_table.dwe-route.id}"
}

// create a First security group allow access to the Instance Name i-RHEL-Node via ssh & HTTP for listed IPs.

resource "aws_security_group" "dwe-sg-ssh" {
  name        = "dwe-sg-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.dwe-vpc.id}"
 
  // Inbound Connection to Node 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.my_ip
  }
// Inbound Connection to Node - Master Node Public IP Allowed
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["xx.xx.xx.xxx/32"]
  }

// Inbound Connection to Node - Master Node Private IP Allowed

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["xx.xx.xx.xxx/32"]
  }

// Inbound Connection to Node - Local Desktop public IP Allowed

// ingress {
//  from_port   = 80
// to_port     = 80
// protocol    = "tcp"
// cidr_blocks = local.my_ip
// }

//Once HTTPS starts working - Restrict access to Inbound port 80 (HTTP) to Only Local PC public IP.

 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // Outbound allow access to the internet

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "SecurityGroup-Node"
  }
}

// create First RHEL 8.0 linux instances associated with Security Group SecurityGroup-Node

resource "aws_instance" "i-redhat-linux-prod" {
  ami                         = "ami-087c2c50437d0b80d"
  instance_type               = "t2.micro"
  key_name                    = "west2"
  vpc_security_group_ids      = ["${aws_security_group.dwe-sg-ssh.id}"]
  subnet_id                   = "${aws_subnet.dwe-subnet.id}"
  associate_public_ip_address = "true"
 
 tags = {
    Name = "i-RHEL-Node"
  } 
}

// create Second Securiy Group and associate to the Second RHEL 8.0 Master(Ansible Controller) Instance, allowed inbound connection via SSH, HTTP from any IPs. This will be use a Ansible Controller 


resource "aws_security_group" "dwe-master" {
  name        = "dwe-master"
  description = "Allow SSH ,HTTP & HTTPS inbound traffic from Any source"
  vpc_id      = "${aws_vpc.dwe-vpc.id}"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
	}
  // Outbound allow access to the internet

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "SecurityGroup-Master"
  }
}
// Second RHEL 8.0 Instance associated with Security Group Name SecurityGroup-Master

resource "aws_instance" "i-redhat-linux-Master" {
  ami                         = "ami-087c2c50437d0b80d"
  instance_type               = "t2.micro"
  key_name                    = "west2"
  vpc_security_group_ids      = ["${aws_security_group.dwe-master.id}"]
  subnet_id                   = "${aws_subnet.dwe-subnet.id}"
  associate_public_ip_address = "true"
 
 tags = {
    Name = "i-RHEL-Master"
  } 
}
 

