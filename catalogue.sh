#!/bin/bash

set -e
failure(){
    echo "Error on line $1:$2"
}
trap 'failure "${LINENO}" "$BASH_COMMAND"' ERR

USERID=$(id -u)
TIME_STAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2....$R FAILURE $N"
        exit 1
    else
        echo -e "$2....$G SUCCESS $N"
    fi
}


if [ $USERID -ne 0 ]
then
    echo "Please run this script as super user"
    exit 1
else
    echo "Running the script as super user"
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs module"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:20 module"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs package"

useradd roboshop &>>$LOGFILE || true
VALIDATE $? "Creating roboshop user"

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating /app directory"

cd /app &>>$LOGFILE
VALIDATE $? "Changing directory to /app"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>>$LOGFILE
VALIDATE $? "Downloading catalogue code"

unzip -o /tmp/catalogue.zip &>>$LOGFILE
VALIDATE $? "Extracting catalogue code"

npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies for catalogue"

cp /home/ec2-user/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGFILE
VALIDATE $? "Copying catalogue.service file to systemd"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable catalogue &>>$LOGFILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue &>>$LOGFILE
VALIDATE $? "Starting catalogue service"

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGFILE
VALIDATE $? "Copying mongo.repo file to yum.repos.d"

dnf install -y mongodb-mongosh &>>$LOGFILE
VALIDATE $? "Installing mongo shell package"

SCHEMA_EXISTS=$(mongosh --host mongodb.surya-devops.online --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')") &>>$LOGFILE
if [ $SCHEMA_EXISTS -lt 0 ]
then
    echo "Catalogue schema doesn't exist. Loading Schema"
    mongosh --host mongodb.surya-devops.online </app/schema/catalogue.js &>>$LOGFILE
    VALIDATE $? "Loading catalogue schema to mongodb"
else
    echo -e "Catalogue schema already exists... $Y SKIPPING $N"
fi
