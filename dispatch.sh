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

dnf install golang -y &>>$LOGFILE
VALIDATE $? "Installing golang package"

if ! id roboshop &>>$LOGFILE
then
    echo "Creating 'roboshop' user"
    useradd roboshop
    VALIDATE $? "Installing golang package"
else
    echo -e "User 'roboshop' already exists... $Y SKIPPING $N " | tee -a $LOGFILE
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-builds.s3.amazonaws.com/dispatch.zip &>>$LOGFILE
VALIDATE $? "Downloading dispatch code"

cd /app &>>$LOGFILE
VALIDATE $? "Changing directory to /app"

go mod init dispatch &>>$LOGFILE
VALIDATE $? "Initializing go module"

go get &>>$LOGFILE
VALIDATE $? "Dowloading go dependencies"

go build &>>$LOGFILE
VALIDATE $? "Building dispatch application"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/dispatch.service &>>$LOGFILE
VALIDATE $? "Copying dispatch systemd service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable dispatch &>>$LOGFILE
VALIDATE $? "Enabling dispatch service"

systemctl start dispatch &>>$LOGFILE
VALIDATE $? "Starting dispatch service"