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

dnf install python3.11 gcc python3-devel -y &>>$LOGFILE
VALIDATE $? "Installing python3.11 and dependencies"

if ! id roboshop &>>$LOGFILE
then
    echo "Creating 'roboshop' user"
    useradd roboshop &>>$LOGFILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "User 'roboshop' already exists... $Y SKIPPING $N " | tee -a $LOGFILE
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>>$LOGFILE
VALIDATE $? "Installing payment code"

cd /app &>>$LOGFILE
VALIDATE $? "Changing directory to /app"

unzip -o /tmp/payment.zip &>>$LOGFILE
VALIDATE $? "Extracting payment code"

pip3.11 install -r requirements.txt &>>$LOGFILE
VALIDATE $? "Installing payment dependencies"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/payment.service &>>$LOGFILE
VALIDATE $? "Copying payment systemd service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable payment &>>$LOGFILE
VALIDATE $? "Enabling payment service"

systemctl start payment &>>$LOGFILE
VALIDATE $? "Starting payment service"