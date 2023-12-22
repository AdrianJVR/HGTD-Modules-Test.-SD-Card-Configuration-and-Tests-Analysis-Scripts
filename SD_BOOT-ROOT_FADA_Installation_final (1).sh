cd 
SD='user'; #This is the SD card password by default; if there is another one change it here.
sudo apt install moreutils
sudo apt install sshpass
sudo apt-get install git 
git config --global http.sslVerify "false"
git clone https://gitlab.cern.ch/atlas-hgtd/Electronics/FADA.git
cd FADA
git checkout fastfada2asic
cd firmware/FastFADA2ASIC
sudo ./clean; ./compile
cd boot_files/ALTIROCv2
#sudo ./cp_boot.sh 
lsblk
read -p "Write the name of your SD card: " SDcard
(
echo d
echo ""
echo d
echo ""
echo d
echo ""
echo d
echo ""
echo n
echo p
echo ""
echo ""
echo +1G
echo a
echo p 
echo w) | sudo fdisk /dev/$SDcard 
sudo mkfs.vfat -F 32 -n BOOT /dev/${SDcard}1
(
echo n
echo p
echo ""
echo ""
echo ""
echo p 
echo w) | sudo fdisk /dev/$SDcard 
sudo umount /dev/${SDcard}2
sudo mkfs.ext4 -L ROOT /dev/${SDcard}2


cd
sudo rm -r Boot_folder
mkdir -p Boot_folder
cd Boot_folder
wget https://box.in2p3.fr/index.php/s/jBQNG4tM6Lcqynt/download
sudo unzip download
cd BOOT_content
#sudo mv BOOT_content/BOOT.BIN  BOOT_content/boot.scr BOOT_content/image.ub BOOT_content/system.dtb BOOT_content/uEnv.txt 
sudo tar -cvzf boot.tar.gz BOOT.BIN boot.scr image.ub system.dtb uEnv.txt 
cd
sudo mount /dev/${SDcard}1 /mnt
sudo tar -xzf Boot_folder/BOOT_content/boot.tar.gz -C /mnt/ --no-same-owner
sudo umount /mnt

sudo rm -r Root_folder
mkdir -p Root_folder
cd Root_folder
wget https://box.in2p3.fr/index.php/s/dr4WXbENW8BYHfk/download
sudo unzip download
cd
sudo mount /dev/${SDcard}2 /mnt
sudo tar --numeric-owner -xzf Root_folder/ROOT_tar/rootfs_jammy.tar.gz  -C /mnt/
sudo umount /mnt
cd

echo "Now, If you want to work in this same computer you will have to change your SD card IP address"

while true; do
read -p "Do you want to work (Measurments and analysis) in this computer? (y/n) " yn
case $yn in 
	[yY] ) echo "ok, we will proceed. Plug your SD card to the fpga board and turn it on";
	       read -p "Type ENTER when it is already done" a;
	       echo "" 
	       ip -br l | awk '$1 !~ "lo|vir|wl" { print $1}';
           echo "From the above list, copy here the code of your Ethernet interface: " 
           read code1 
           v=$code1;
           t=$(ip addr show $v | grep "inet\b" | awk '{print $2}' | cut -d/ -f1);
           echo "The IP address of this computer is: $t"
           #code1=$(ip a | grep inet | grep "$t" | awk -F " " '{print $7}');
           netmask=$(ifdata -pn $v);
           echo "Write a new IP address for your SD card:";                         
           read IPaddr2;
           m=$IPaddr2;
           sudo ifconfig $v 10.10.0.95 netmask $netmask;
           sshpass -p $SD ssh -t user@10.10.0.98 "mkdir -p /home/user/Measurements; cd /etc/netplan/; sudo sed -i 's|10.10.0.98|$m|g' '01-netcfg.yaml'; sudo sed -i 's|10.10.0.100|$t|g' '01-netcfg.yaml'; cd";
           sudo ifconfig $v $t netmask $netmask;
           read -p "Ok, we will proceed to Install FADA in the SD card. Reset your fpga board (Wait around 10 seconds between the switch is on and off). Type 'Enter' when it is done." b;
           echo "The SD card needs time to reset its IP address. Let's wait around 1 min.";
           hour=0;
           min=0;
           sec=60;
           while [ $hour -ge 0 ]; do
                 while [ $min -ge 0 ]; do
                         while [ $sec -ge 0 ]; do
                                 echo -ne "$hour:$min:$sec\033[0K\r"
                                 let "sec=sec-1"
                                 sleep 1
                         done
                         sec=59
                         let "min=min-1"
                 done
                 min=59
                 let "hour=hour-1"
           done
	       read -p "Ready. Type 'ENTER' now" a; 
	       sshpass -p $SD ssh -t user@$m  "sudo apt-get install git; git config --global http.sslVerify 'false'; git clone https://gitlab.cern.ch/atlas-hgtd/Electronics/FADA.git; cd FADA; git checkout fastfada2asic; cd firmware/FastFADA2ASIC; sudo ./clean; sudo ./compile; cd boot_files/ALTIROCv2";
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac
done





