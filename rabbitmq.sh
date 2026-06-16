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

# Erlang is a dependency for RabbitMQ, so we need to setup Erlang repo first before setting up RabbitMQ repo. 
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>>$LOGFILE
VALIDATE $? "Configuring YUM repos for Erlang"

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>>$LOGFILE
VALIDATE $? "Configuring YUM repos for RabbitMQ"

dnf install rabbitmq-server -y &>>$LOGFILE
VALIDATE $? "Installing RabbitMQ Server"

systemctl enable rabbitmq-server &>>$LOGFILE
VALIDATE $? "Enabling RabbitMQ service"

systemctl start rabbitmq-server &>>$LOGFILE
VALIDATE $? "Starting RabbitMQ service"

rabbitmqctl add_user roboshop roboshop123 &>>$LOGFILE
VALIDATE $? "Adding RabbitMQ user for roboshop"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOGFILE
VALIDATE $? "Setting permissions for RabbitMQ user"