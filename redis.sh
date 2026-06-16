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

dnf install redis -y &>>$LOGFILE
VALIDATE $? "Installing redis package"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>>$LOGFILE
VALIDATE $? "Allowing remote connection to redis service"

systemctl enable redis &>>$LOGFILE
VALIDATE $? "Enabling redis service"

systemctl start redis &>>$LOGFILE
VALIDATE $? "Starting redis service"