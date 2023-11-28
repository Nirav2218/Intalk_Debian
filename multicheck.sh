#! /bin/bash
# ask for how many instance we use for installation
echo "is it single or multi instance installation ?"
echo "select A or B"
echo "A. Single B. Multiple"
read -r inst_type
# for single instance
if [[ "$inst_type" == "a" || "$inst_type" == "A" ]]; then
    echo "It is a single instance installation"
  
    chmod +x start
   ./start
# for multi instance
elif [[ "$inst_type" == "b" || "$inst_type" == "B" ]]; then
    ./start
else
    echo "select appropriate option"
fi
