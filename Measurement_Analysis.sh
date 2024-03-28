cd
#sudo apt install python3-pip
#pip install socketscpi

PORT=9221
Inst1=192.168.0.2
Inst2=192.168.0.3
HVAddr=192.168.0.4
HVDelt=5

SD='user'; #This is the SD card password by default; if there is another one change it here.
set -- $(eval echo "~$user")
home=$1
Measurement_Path='Desktop/FastFadaMeasurements2'
cd
mkdir -p $Measurement_Path
echo ""
read -p "Remember to plug your SD card and turn on the fpga board. Aditionally, Connect the module for test and turn all your Power Supplies on. Type 'Enter' to continue when it is done: " a
echo ""

python3 -c "import socket; import socketscpi as scpi; supply1 = scpi.SocketInstrument('$Inst1', $PORT, verboseErrCheck=True); supply1.write('OPALL 1'); supply2 = scpi.SocketInstrument('$Inst2', $PORT, verboseErrCheck=True); supply2.write('OPALL 1')"

ip -br l | awk '$1 !~ "lo|vir|wl" { print $1}'
echo "From the above list, copy here the code of your Ethernet interface: "
read code1
v=$code1 
t=$(ip addr show $v | grep "inet\b" | awk '{print $2}' | cut -d/ -f1) 
echo "From the above list, copy here the code of your Network interface: "
read code2
s=$code2
u=$(id -un)
#read -p "Write $u password:" passwd
#p=$passwd
cd
more Downloads/SDCard_IPAdrr_list.txt
read -p "Introduce the number of your SD Card IP Address:" j
IPsd=$(echo "$(awk "{if(NR==$j) print $2}" Downloads/SDCard_IPAdrr_list.txt)" | cut -c3-)
m=$IPsd
sudo sysctl -p
#net.ipv4.ip_forward = 1
sudo iptables -t nat -A POSTROUTING -o $s -j MASQUERADE
sshpass -p $SD ssh -t user@$m "echo $p | sudo sshfs -o allow_other $u@$t:$home/$Measurement_Path /home/user/Measurements/"
Pow='off'

Power_Supply_changes() {
  python3 -c "import socket; import socketscpi as scpi; supply1 = scpi.SocketInstrument('$Inst1', $PORT, verboseErrCheck=True); supply2 = scpi.SocketInstrument('$Inst2', $PORT, verboseErrCheck=True); supply1.write('OPALL 0'); supply2.write('OPALL 0')"
  read -p "Type the voltage for first Power Supply:" V1
  python3 -c "import socket; import socketscpi as scpi; supply1 = scpi.SocketInstrument('$Inst1', $PORT, verboseErrCheck=True); supply1.write('V1 $V1')"
  read -p "Type the voltage for second Power Supply:" V2
  python3 -c "import socket; import socketscpi as scpi; supply1 = scpi.SocketInstrument('$Inst1', $PORT, verboseErrCheck=True); supply1.write('V2 $V2')"
  read -p "Type the voltage for third Power Supply:" V3
  python3 -c "import socket; import socketscpi as scpi; supply2 = scpi.SocketInstrument('$Inst2', $PORT, verboseErrCheck=True); supply2.write('V1 $V3')"
  read -p "Type the voltage for fourth Power Supply:" V4
  python3 -c "import socket; import socketscpi as scpi; supply2 = scpi.SocketInstrument('$Inst2', $PORT, verboseErrCheck=True); supply2.write('V1 $V4')"     
  python3 -c "import socket; import socketscpi as scpi; supply1 = scpi.SocketInstrument('$Inst1', $PORT, verboseErrCheck=True); supply2 = scpi.SocketInstrument('$Inst2', $PORT, verboseErrCheck=True); supply1.write('OPALL 1'); supply2.write('OPALL 1')"
}

Bump_Connection () { 
  cd
  more Downloads/Modules_list.txt
  read -p "Introduce the number of your module:" j
  P=$(echo "$(awk "{if(NR==$j) print $2}" Downloads/Modules_list.txt)" | cut -c3-)
  yourMeasurementName=${P}${now}
  yourMeasurementOld="$P"
  echo $yourMeasurementName
  bump='bump'
  bumpname="${bump}_${yourMeasurementName}"
  echo $bumpname
  read -p "If you want to disable chip 0 type '0'. If you want to disable chip 1 type '1'. If you want to test both chips type any other key." h
  if [ $h == 0 ]; then
  sshpass -p $SD ssh -t user@$m "cd ~/FADA/firmware/FastFADA2ASIC;
                                 source check_bump_connection_manual.sh $bumpname $Pow '--disable 0'"
  elif [ $h == 1 ]; then
  sshpass -p $SD ssh -t user@$m "cd ~/FADA/firmware/FastFADA2ASIC;
                                 source check_bump_connection_manual.sh $bumpname $Pow '--disable 1'"
  else
   sshpass -p $SD ssh -t user@$m "cd ~/FADA/firmware/FastFADA2ASIC;
                                 source check_bump_connection_manual.sh $bumpname $Pow"
  fi
  mkdir -p $Measurement_Path/"$yourMeasurementName"/bumpConnection
  cd FADA/software/analysis/FastFadaAnalysis
  python3 makeEffCurve.py --module --input $home/$Measurement_Path/Measurements2ASIC/bump_"$yourMeasurementName"_Hv$Pow1/thresScan/B_22_On_col_Inj_col_N_20_Q_38/ --prefix HV_"$Pow1"_Q_38 --output-dir $home/$Measurement_Path/"$yourMeasurementName"/bumpConnection
  cd
}

Tuning_Module () {
  cd
  more Downloads/Modules_list.txt
  read -p "Introduce the number of your module:" j
  P=$(echo "$(awk "{if(NR==$j) print $2}" Downloads/Modules_list.txt)" | cut -c3-)
  tunning='TM_'
  HvPow='_Hv'
  yourMeasurementName=${tunning}${P}${now}
  yourModuleName=$P
  TM_yourModuleName=${tunning}${P}
  echo $yourMeasurementName
  echo ""
  echo "Do you want to do a VTH scan (global threshold)?"
  read -p "If you want, type 1, if not, type any other key" Scna
  if [ $Scna == 1 ]; then
  sshpass -p $SD ssh -t user@$m "sudo mkdir -p config/vthc/$yourModuleName;
                                 cd ~/FADA/firmware/FastFADA2ASIC;
                                 source thresh_scan_Q20.sh '$yourMeasurementName'"
  mkdir -p $Measurement_Path/"$TM_yourModuleName"/"$yourMeasurementName"  
  cd FADA/software/analysis/FastFadaAnalysis
  python3 makeEffCurve.py --module --input $home/$Measurement_Path/Measurements2ASIC/$yourMeasurementName/thresScan/B_22_On_col_Inj_col_N_20_Q_20/ --output-dir $home/$Measurement_Path/"$TM_yourModuleName"/"$yourMeasurementName"   
  fi
  cd
  echo "Now, Do you want to do a VTHC scan (per pixel threshold)?"
  read -p "If you want, type 1, if not, type any other key" Scnb
  if [ $Scnb == 1 ]; then
  echo "The values of VTH0 and VTH1 (median thresholds for the two matrices) are indicated at the top of the 2D maps for each chip"
  read -p "Type VTH0:" VTH0
  read -p "Type VTH1:" VTH1
  sshpass -p $SD ssh -t user@$m "cd ~/FADA/firmware/FastFADA2ASIC;
                                 source vthc_scan_Q20.sh "$yourMeasurementName" $VTH0 $VTH1" 
  cd FADA/software/analysis/FastFadaAnalysis
  python3 makeEffCurve.py --module --input $home/$Measurement_Path/Measurements2ASIC/$yourMeasurementName/vthcScan/B_22_On_col_Inj_col_N_20_Q_20/ --output-dir $home/$Measurement_Path/"$TM_yourModuleName"/"$yourMeasurementName" 
  cd
  cd $Measurement_Path/"$TM_yourModuleName"/"$yourMeasurementName"
  scp -r asic0_vthc.txt asic1_vthc.txt user@$m:~/.
  fi
  cd
  echo "Now, Do you wanr to do a c) charge scan : verify the tuning?" 
  read -p "If you want, type 1, if not, type any other key" Scnc 
  if [ $Scnc == 1 ]; then
  sshpass -p $SD ssh -t user@$m "sudo mv asic0_vthc.txt asic1_vthc.txt config/vthc/$yourModuleName
                                 cd 
                                 cd ~/FADA/firmware/FastFADA2ASIC;
                                 source charge_scan.sh '$yourMeasurementName' $VTH0 $VTH1 /home/user/config/vthc/'$yourModuleName'/asic0_vthc.txt /home/user/config/vthc/'$yourModuleName'/asic1_vthc.txt"
  cd FADA/software/analysis/FastFadaAnalysis
  python3 makeEffCurve.py --module --input $home/$Measurement_Path/Measurements2ASIC/$yourMeasurementName/chargeScan/B_22_On_col_Inj_col_N_20_Q_12/ --output-dir $home/$Measurement_Path/"$TM_yourModuleName"/"$yourMeasurementName"
  fi
  python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('OPALL 0')"  
}

while true; do
echo ""
echo "Do you want to do a new measurement?"
echo "For 'Bump Connection' type '1'."
echo "For 'Tuning a module' type '2'."
echo "Type any other key to cancel and exit." 
read x
case $x in 
   	[1] ) echo ""
	      echo "You have chosen a Bump connection test."
	      read -p "Type '1' if you want a 'High Voltage OFF' Bump Connection test. Type 2 if you want a 'High Voltage ON' one. Type 3 to analize. Type any other key to cancel.:" y  
	      if [ $y == 1 ]; then
	      echo "You have chosen a Bump connection test with High voltage OFF."
	      read -p "Do you want to change the Voltage value?. Type '1' to do it, if not type other key:" z
	       if [ $z == 1 ]; then
           Power_Supply_changes
	       fi
	      Pow='off'
	      Pow1='Off'
	      now=''
	      Bump_Connection
	      elif [ $y == 2 ]; then
	      echo "You have chosen a Bump connection test with High voltage ON."
	      read -p "Do you want to change the Voltage value?. Type '1' to do it, if not type other key:" z
	      if [ $z == 1 ]; then
          Power_Supply_changes
	      fi
	      HV=''
              read -p "Type the voltage for your High Voltage Power Supply:" HV
              python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('V1 $HV')"
              read -p "Type the current limit for your High Voltage Power Supply:" I
	      python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('I1 $I')"
	      python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('OPALL 1')"
	      Pow='on'
	      Pow1='On'
	      now=_$(date +"%Y-%m-%d")_$HV'V'
	      read -p "Type Enter to see if you can make this HV measurement" q
	      python3 -c "import socket; import sys; import subprocess; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); from io import StringIO; import sys; buffer = StringIO(); sys.stdout = buffer; supply3.write('V1O?'); print(supply3.read()); print_output = buffer.getvalue(); sys.stdout = sys.__stdout__; print_output = print_output[:-2]; f = open('test.txt', 'w'); sys.stdout = f; print(print_output); f.close()"
	      cat test.txt
          HV_T=$(cat test.txt)
          echo "Your output is $HV_T V"
          now=_$(date +"%Y-%m-%d")_$HV_T'V'
          #echo  "$HV_T-$HV < 0" | bc 
          bool=$(echo "$HV-$HV_T < $HVDelt" | bc) 
          boolN=$bool 
          #echo $boolN
          rm -r test.txt
	      if [ $boolN == 1 ]; then
	       Bump_Connection
	       echo "A bump connection test with a High voltage On is done."
	       while true; do
	       read -p "Do you want to do an analysis already? (y/n)" yn
               case $yn in 
	           [yY] ) echo ok, we will proceed;
	           rsync -a $Measurement_Path/"$yourMeasurementOld"/bumpConnection/ $Measurement_Path/"$yourMeasurementName"/bumpConnection;       
	           cd FADA/software/analysis/FastFadaAnalysis;
	           python3 bump_connection.py --input $home/$Measurement_Path/"$yourMeasurementName"/bumpConnection --output-dir $home/$Measurement_Path/"$yourMeasurementName" --upper-thresh 35 --yratio-min 5 --yratio-max 40;
		       break;;
	           [nN] ) echo exiting...;
		       break;;
	           * ) echo invalid response;;
               esac         
               done
	      else
	      echo "The High Volyage input doesn't correspond with the High Voltage output. Change the current or the Voltage."
	      python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('OPALL 0')"
	      echo exiting...;
	      #break;
	      fi
	      elif [ $y == 3 ]; then
	      cd
          more Downloads/Modules_list.txt
          read -p "Introduce the number of your module for analysis:" j
          P=$(echo "$(awk "{if(NR==$j) print $2}" Downloads/Modules_list.txt)" | cut -c3-)
          yourMeasurementOld="$P"
          cd $Measurement_Path
          ls -d ${yourMeasurementOld}_*
          read -p "Copy Here the full name of the HV Measurement you want for analysis:" yourMeasurementName
          cd
          rsync -a $Measurement_Path/"$yourMeasurementOld"/bumpConnection/ $Measurement_Path/$yourMeasurementName/bumpConnection;        
	      cd FADA/software/analysis/FastFadaAnalysis;
	      python3 bump_connection.py --input $home/$Measurement_Path/$yourMeasurementName/bumpConnection --output-dir $home/$Measurement_Path/$yourMeasurementName --upper-thresh 35 --yratio-min 5 --yratio-max 40;
	      else 
	      echo 'No measurement will be done.'
	      fi
	;;
	[2] ) echo ""
	      echo "You have chosen a Tuning module test."
	      read -p "Turn your High Voltage Power Supply on. Type 'Enter' when it is done." x
          read -p "Type the voltage for your High Voltage Power Supply:" HV
          python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('V1 $HV')"
          read -p "Type the current limit for your High Voltage Power Supply:" I
	      python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('I1 $I')"
	      python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('OPALL 1')"
	      now=_$(date +"%Y-%m-%d")_$HV'V'       
		  read -p "Type Enter to see if you can make this HV measurement" q
	      python3 -c "import socket; import sys; import subprocess; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); from io import StringIO; import sys; buffer = StringIO(); sys.stdout = buffer; supply3.write('V1O?'); print(supply3.read()); print_output = buffer.getvalue(); sys.stdout = sys.__stdout__; print_output = print_output[:-2]; f = open('test.txt', 'w'); sys.stdout = f; print(print_output); f.close()"
	      cat test.txt
          HV_T=$(cat test.txt)
          echo "Your output is $HV_T V"
          #echo  "$HV_T-$HV < 0" | bc 
          bool=$(echo "$HV-$HV_T < $HVDelt" | bc)
          boolN=$bool 
          echo $boolN
          rm -r test.txt
	      if [ $bool == 1 ]; then
	       Pow='on'
           Pow1='On'
	       Tuning_Module
	      else
	      echo "The High Volyage input doesn't correspond with the High Voltage output. Change the current or the Voltage."
	      python3 -c "import socket; import socketscpi as scpi; supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('OPALL 0')"
	      echo exiting...;
	      #break;
	      fi
	  ;;
	  * ) echo exiting...
	     python3 -c "import socket; import socketscpi as scpi; supply1 = scpi.SocketInstrument('$Inst1', $PORT, verboseErrCheck=True); supply1.write('OPALL 0'); supply2 = scpi.SocketInstrument('$Inst2', $PORT, verboseErrCheck=True); supply2.write('OPALL 0'); supply3 = scpi.SocketInstrument('$HVAddr', $PORT, verboseErrCheck=True); supply3.write('OPALL 0');"
	     exit;;
esac
done
