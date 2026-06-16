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

curl -L -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip &>>$LOGFILE
VALIDATE $? "Downloading User Code"

cd /app  &>>$LOGFILE
VALIDATE $? "Changing directory to /app"

unzip /tmp/user.zip &>>$LOGFILE
VALIDATE $? "Extracting user code"

npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies for user service"

cp /home/ec2-user/roboshop-shell/user.service /etc/systemd/system/user.service &>>$LOGFILE
VALIDATE $? "Copying user.service to systemd"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable user &>>$LOGFILE
VALIDATE $? "Enabling user service"

systemctl start user &>>$LOGFILE
VALIDATE $? "Starting user service"

cp /home/ec2-user/roboshop-shell/mongo.repo  /etc/yum.repos.d/mongo.repo &>>$LOGFILE
VALIDATE $? "Copying mongo.repo file to yum.repos.d"

dnf install mongodb-mongosh -y &>>$LOGFILE
VALIDATE $? "Installing mongoshell package"

mongosh --host mongodb.surya-devops.online </app/schema/user.js &>>$LOGFILE
VALIDATE $? "Loading user schema to mongodb"