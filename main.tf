provider "aws" {
    region = "us-east-1"
    #revisar region
}
resource "aws_vpc" "vpc_avance_devops" {
    cidr_block = "10.0.0.0/20"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "vpc_avance_devops"
    }
  
}
#----------------------public subnet----------------------
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true  
    tags = {
        Name = "public_subnet"
    }
  
}
#----------------------private subnet----------------------
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false 
}

#----------------private subnet 2----------------------
resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
    cidr_block = "10.0.2.0/24"
    availability_zone       = "us-east-1c" #zona de disponibilidad
    map_public_ip_on_launch = false

    }

#----------------igw----------------------
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
    tags = {
        Name = "igw"
    }
  
}
#----------------------public route table----------------------
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id 
    }
    tags = {
        Name = "public_route_table"
    }
}

#----------------------private route table----------------------
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
}

#----------------------public route table association----------------------
resource "aws_route_table_association" "public_route_association" {
    subnet_id = aws_subnet.public_subnet.id #subnet id
    route_table_id = aws_route_table.public_route_table.id #route table id   
  
}

#----------------------private route table association----------------------
resource "aws_route_table_association" "private_route_association" {
    subnet_id = aws_subnet.private_subnet.id #subnet id
    route_table_id = aws_route_table.private_route_table.id #route table id
}

#--------------------private route table association private subnet 2-------------------------
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

#----------------------SG linux jumpserver----------------------
 resource "aws_security_group" "SG-linux-jumpserver" {
        vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
        name = "SG-linux-jumpserver"
        description = "Security group for linux jumpserver"
        ingress {
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = [ "0.0.0.0/0" ]
      
    }
        egress {
            from_port = 0
            to_port = 0
            protocol = -1
            cidr_blocks = [ "0.0.0.0/0" ]

     }
        tags = {
            Name = "SG-linux-jumpserver"
        }
 
       
}
 #--------------------Sg linux backend-------------------------
resource "aws_security_group" "SG-linux-back-end" {
    vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
    name = "SG-linux-back-end"
    description = "Security group for linux back-end Server"
    #ssh ingress and egress rules
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${aws_instance.linux-jumpserver.private_ip}/32" ] #subnet id
    }
    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["${aws_instance.linux-webserver.private_ip}/32"] 
    }
   
   egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ] 
   }
    tags = {
        Name = "SG-linux-back-end"

    }
}
#----------------------SG linux webserver----------------------
resource "aws_security_group" "SG-linux-webserver" {
  vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
  name = "SG-linux-webserver"
  description = "Security group para servidor web Linux"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "${aws_instance.linux-jumpserver.private_ip}/32" ] #subnet id

    }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ] #subnet id 
    }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ] #permite todo el trafico de salida para el uso de frameworks
    }
   
  
    tags = {
        Name = "SG-linux-webserver"
    }
}

#----------------------linux jumpserver----------------------
resource "aws_instance" "linux-jumpserver" {
    ami = "ami-084568db4383264d4" 
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id #subnet id
    vpc_security_group_ids = [aws_security_group.SG-linux-jumpserver.id] #security group id
    key_name = "vockey" #key pair name
    tags = {
        Name = "linux-jumpserver"
    }
  
}
#----------------------linux webserver----------------------
resource "aws_instance" "linux-webserver" {
    ami = "ami-084568db4383264d4" 
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id #subnet id
    vpc_security_group_ids = [aws_security_group.SG-linux-webserver.id] #security group id
    key_name = "vockey" #key pair name
    tags = {
        Name = "linux-webserver"
    }
  
}
#----------------------linux back-end----------------------
resource "aws_instance" "linux-back-end" {
    ami = "ami-084568db4383264d4" 
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet.id #subnet id
    vpc_security_group_ids = [aws_security_group.SG-linux-back-end.id] #security group id
    key_name = "vockey" #key pair name
    tags = {
        Name = "linux-back-end"
    }
  
}
#----------------------subnet group BD----------------------
resource "aws_db_subnet_group" "devops_subnet_group" {
  name       = "devops-subnet-group"
  subnet_ids = [ aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id ]  # Aquí referencias tu subnet privada existente
  tags = {
    Name = "DB Subnet Group"
  }
}

#----------------------sg db----------------------

resource "aws_security_group" "sg_db" {
  vpc_id = aws_vpc.vpc_avance_devops.id #vpc id
  name = "sg_db"


  ingress {
    from_port   = 5432  # Puerto de PostgreSQL
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [ "${aws_instance.linux-back-end.private_ip}/32" ] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ] #permite todo el trafico de salida para el uso de frameworks
  }
}


resource "aws_db_instance" "BD" {
  allocated_storage = 20
  engine = "postgres"
  engine_version = "17.2"
  instance_class = "db.t3.micro"
  db_name = "bddevops"
  username = "db_admin_user"
  password = "SecurePass123!" 
  vpc_security_group_ids = [aws_security_group.sg_db.id] 
  db_subnet_group_name = aws_db_subnet_group.devops_subnet_group.name 
  publicly_accessible = false #no tiene ip publica
  skip_final_snapshot = true #no se crea un snapshot final al eliminar la instancia, se pierde todo

}

#output 

output "linux-webserver_public_ip" {
    value = aws_instance.linux-webserver.public_ip
    description = "ip publica de la instancia linux-webserver"
}