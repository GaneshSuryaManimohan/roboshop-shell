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

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing nginx package"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling nginx service"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing default nginx content"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>>$LOGFILE
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html &>>$LOGFILE
VALIDATE $? "Changing directory to nginx html"

unzip /tmp/web.zip &>>$LOGFILE
VALIDATE $? "Extracting frontend code"

cp /home/ec2-user/roboshop-shell/roboshop.conf /etc/nginx/default.d/roboshop.conf &>>$LOGFILE
VALIDATE $? "Copying roboshop.conf to nginx default.d"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting nginx service"