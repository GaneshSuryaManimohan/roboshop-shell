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

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating /app directory"

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing mysql-server package"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling mysqld service"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Starting mysqld service"

if [ -f /app/mysql_password_set ]
then
    echo "Root password is already set, skipping" | tee -a $LOGFILE
else
    mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOGFILE
    VALIDATE $? "Set up root password for mysql"
    touch /app/mysql_password_set
fi