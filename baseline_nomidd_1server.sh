#!/bin/bash

suffix=.westeurope.cloudapp.azure.com

numberVMs=8
repetitions=3

resource_group=asl
nethzid=nikolijo
vm_name_base=foraslvms

vms=(1 2 3 4 5 6 7 8)
memtier=(1 2 3)
memcached=(6 )
memcached_ports=(8080 )

private_ips_memtier=()
private_ips_memcached=()

memtier_threads=2 									# number of threads in memtier
memtier_clients_pt=(1 5 8 14 19 23 28 32 42 52 64)	# number of virtual clients per thread in memtier 1 5 9 14 19 23 28
test_time=90 										# runtime of memtier in seconds
SET_ratio=1
GET_ratio=0

client_stats_file_basename="client_stats"
# output_file_basename="output_file"
json_output_file_basename="json_output_file"
dst_folder_basename="data"
subfolder="/baseline_nomidd_1server"

# param1: resource group, param2: vm name
# example: start_one_VM asl foraslvms1
start_one_VM() {
	echo "Starting Virtual Machine" $2
	az vm start --resource-group $1 --name $2 &
	sleep 4
}

# param1: resource group, param2: vm name
# example: stop_one_VM asl foraslvms1
stop_one_VM() {
	echo "Stopping Virtual Machine" $2
	az vm deallocate --resource-group $1 --name $2 &
	sleep 4
}

# param1: resource group, param2: vm name, param3: vm id
get_private_ip_one_vm() {
	if [ $3 -le 3 ]
		then
			read private_mmt_ip <<< $(az vm show --resource-group $1 --name $2 --query privateIps -d --out tsv)
			private_ips_memtier+=($private_mmt_ip)
			echo "Memtier private ip fetched is "${private_ips_memtier[$((${#private_ips_memtier[@]}-1))]}
	elif [ $3 -le 5 ]
		then
			read private_mdw_ip <<< $(az vm show --resource-group $1 --name $2 --query privateIps -d --out tsv)
			private_ips_middleware+=($private_mdw_ip)
			echo "Middleware private ip fetched is "${private_ips_middleware[$((${#private_ips_middleware[@]}-1))]}
	else
		read private_mcd_ip <<< $(az vm show --resource-group $1 --name $2 --query privateIps -d --out tsv)
		private_ips_memcached+=($private_mcd_ip)
		echo "Memcached private ip fetched is "${private_ips_memcached[$((${#private_ips_memcached[@]}-1))]}
	fi
}

# param1: username, param2: public ip address or DNS name, param3: command to be executed
# example: nikolijo@nikolijoforaslvms1.westeurope.cloudapp.azure.com
connect() {
	ssh -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2 "$3"
}

# param1: username, param2: public ip address or DNS name, param3: command to be executed
# example: nikolijo@nikolijoforaslvms1.westeurope.cloudapp.azure.com
connect_persistent() {
	ssh -o "StrictHostKeyChecking no" -o "CheckHostIP no" -o ConnectTimeout=100 -o ConnectionAttempts=150 $1@$2 "$3"
}

# param1: vm_id, param3: command to be executed
connect_fast() {
	connect $nethzid $nethzid$vm_name_base$1$suffix "$2"
}

# param1: vm_id, param3: command to be executed
connect_persistant_fast() {
	connect_persistent $nethzid $nethzid$vm_name_base$1$suffix "$2"
}

# param1: username, param2: public ip address or DNS name
# example: nikolijo@nikolijoforaslvms1.westeurope.cloudapp.azure.com
copyFilesBack() {
	# scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2:$client_stats_file_basename* $1@$2:$output_file_basename* received_reports/
	scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2:$json_output_file_basename* $1@$2:dstat* $1@$2:ping* $dst_folder_basename$subfolder
}

get_memtier_private_ips() {
	echo "Fetching Memtier private ip addresses..."
	for vm_id in "${memtier[@]}"
	do
		get_private_ip_one_vm $resource_group $vm_name_base$vm_id $vm_id
	done
	wait
}

get_memcached_private_ips() {
	echo "Fetching Memcached private ip addresses..."
	for vm_id in "${memcached[@]}"
	do
		get_private_ip_one_vm $resource_group $vm_name_base$vm_id $vm_id
	done
	wait
}

# Starts memcached and memtier virtual machines, one by one
start_all_machines() {
	echo "Starting Memcached Virtual Machines..."
	for vm_id in "${memcached[@]}"
	do
		echo "----------------------------"
		start_one_VM $resource_group $vm_name_base$vm_id
		echo "----------------------------"
		wait
	done
	echo "Memcached Virtual Machine(s) started.."
	echo "Starting Memtier Virtual Machines..."
	for vm_id in "${memtier[@]}"
	do
		echo "----------------------------"
		start_one_VM $resource_group $vm_name_base$vm_id
		echo "----------------------------"
		wait
	done
	echo "Memtier Virtual Machine(s) started.."	
}

# Stops memcached and memtier virtual machines, all in parallel, waits for all to finish
stop_all_machines() {
	echo "Stopping Memtier Virtual Machines..."
	for vm_id in "${memtier[@]}"
	do
		echo "++++++++++++++++++++++++++++"
		stop_one_VM $resource_group $vm_name_base$vm_id
		echo "++++++++++++++++++++++++++++"
		sleep 5
	done
	echo "Memtier Virtual Machine(s) stopped.."

	echo "Stopping Memcached Virtual Machines..."
	for vm_id in "${memcached[@]}"
	do
		echo "++++++++++++++++++++++++++++"
		stop_one_VM $resource_group $vm_name_base$vm_id
		echo "++++++++++++++++++++++++++++"
		sleep 5
	done
	echo "Memcached Virtual Machine(s) stopped.."
	wait
}

# Runs one memcached instance on one VM
run_all_memcached() {
	echo "                >> Running memcached ..."
	command_for_memcached=" memcached -t 1 -p "${memcached_ports[0]}" "
	connect_fast ${memcached[0]} "$command_for_memcached" &
	sleep 10
}

# Runs all 3 memtier instances on 3 different VMs in parallel
# param1: client per thread count, param2: repetition
							  # --client-stats="$current_client_stat_file" \
run_all_memtiers() {
	for memtier_vm in "${memtier[@]}"
	do
		# current_client_stat_file=$client_stats_file_basename"_cpt"$1"_rep"$2"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm".log"
		# current_output_file=$output_file_basename"_cpt"$1"_rep"$2"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm".log"
		current_json_output_file=$json_output_file_basename"_cpt"$1"_rep"$2"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm".json"

		command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_memcached[0]}" \
							  --port="${memcached_ports[0]}" \
							  --protocol=memcache_text --data-size=1024 \
							  --expiry-range=9999-10000 \
							  --key-maximum=10000 \
							  --random-data --hide-histogram \
							  --clients="$1" \
							  --threads="$memtier_threads" \
							  --test-time="$test_time" \
							  --ratio="$SET_ratio":"$GET_ratio" \
							  --json-out-file="$current_json_output_file" "
		if [ $memtier_vm -lt 3 ]
			then
				echo "                >> Running memtier "$memtier_vm" ..."
				connect_fast $memtier_vm "$command_for_memtier" &
		else
			echo "                >> Running memtier "$memtier_vm" ..."
			connect_fast $memtier_vm "$command_for_memtier"
		fi			
	done
}

# no params
# copies all files from metiers in same "received_reports" directory
copy_all_files_from_memtiers() {
	echo "                >> Copying files to local computer and removing from remote machine..."
	for memtier_vm in "${memtier[@]}"
	do
		connect_fast $memtier_vm "$command_for_memtier_kill"
		copyFilesBack $nethzid $nethzid$vm_name_base$memtier_vm$suffix
		connect_fast $memtier_vm " rm -r json* dstat* "
	done
	for memcached_vm in "${memcached[@]}"
	do
		copyFilesBack $nethzid $nethzid$vm_name_base$memcached_vm$suffix
		connect_fast $memcached_vm " rm -r dstat* "
	done
}

# param1: client per thread count, param2: repetition, param3 "r" or "w"
run_remote_dstat() {
	echo "                >> Running dstat at "${memtier[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier1_cpt"$1"_rep"$2"_"$3".csv"
	connect_fast ${memtier[0]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memtier[1]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier2_cpt"$1"_rep"$2"_"$3".csv"
	connect_fast ${memtier[1]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memtier[2]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier3_cpt"$1"_rep"$2"_"$3".csv"
	connect_fast ${memtier[2]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memcached[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached1_cpt"$1"_rep"$2"_"$3".csv"
	connect_fast ${memcached[0]} "$command_for_dstat" > /dev/null &
}

kill_dstats() {
	connect_fast ${memtier[0]} "pkill dstat" &>/dev/null &
	connect_fast ${memtier[1]} "pkill dstat" &>/dev/null &
	connect_fast ${memtier[2]} "pkill dstat" &>/dev/null &
	connect_fast ${memcached[0]} "pkill dstat" &>/dev/null &
}

# param1: client per thread count, param2: repetition, param3: "r" or "w"
ping_test() {
	echo "                >> Ping test.."
	connect_fast ${memtier[0]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier1_cpt"$1"_rep"$2"_"$3".txt"
	connect_fast ${memtier[1]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier2_cpt"$1"_rep"$2"_"$3".txt"
	connect_fast ${memtier[2]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier3_cpt"$1"_rep"$2"_"$3".txt"
	echo "                >> Ping test done."
}

# no params
# assumes that all necessary memcached instances are running
# it doesn't matter if memcached is already populated or not
# because SET message updates values as well!
write_only_load() {
	# write-only load
	for client_count in "${memtier_clients_pt[@]}"
	do
		echo "                 ==== THREAD COUNT = "$client_count" ===="
		for rep in `seq 1 1 $repetitions`
		do
			echo "                 ==== REPETITION = "$rep" ===="

			ping_test $client_count $rep "w"

			run_remote_dstat $client_count $rep "w"

			run_all_memtiers $client_count $rep

			kill_dstats

			copy_all_files_from_memtiers
		done
	done
}

# no params
read_only_load() {

	SET_ratio=0
	GET_ratio=1

	for client_count in "${memtier_clients_pt[@]}"
	do
		echo "                 ==== THREAD COUNT = "$client_count" ===="
		for rep in `seq 1 1 $repetitions`
		do
			echo "                 ==== REPETITION = "$rep" ===="

			ping_test $client_count $rep "r"

			run_remote_dstat $client_count $rep "r"

			run_all_memtiers $client_count $rep

			kill_dstats

			copy_all_files_from_memtiers
		done
	done
}

populate_memcached() {
	run_all_memcached

	echo "                >> Populating memcached... "

	for memtier_vm in "${memtier[@]}"
	do
		command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_memcached[0]}" \
							  --port="${memcached_ports[0]}" \
							  --protocol=memcache_text --data-size=1024 \
							  --expiry-range=9999-10000 \
							  --key-maximum=10000 --key-pattern=S:S \
							  --random-data --hide-histogram \
							  --clients=5 \
							  --threads=2 \
							  --test-time="$test_time" \
							  --ratio="$SET_ratio":"$GET_ratio" "
		if [ $memtier_vm -lt 3 ]
			then
				connect_fast $memtier_vm "$command_for_memtier" &
		else 
			connect_fast $memtier_vm "$command_for_memtier"
		fi			
	done
}

kill_all_memcached() {
	connect_fast ${memcached[0]} "$command_for_memcached_kill_basic"
	connect_fast ${memcached[0]} "$command_for_memcached_kill"
}

fix_ssh_keys() {
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms1.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms2.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms3.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms4.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms5.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms6.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms7.westeurope.cloudapp.azure.com
	ssh-keygen -f "/home/jovan/.ssh/known_hosts" -R nikolijoforaslvms8.westeurope.cloudapp.azure.com
}

# Does the following:
#	1. removes any existing reports 
#	2. starts all machines
#	3. gets all private IP addresses
# 	4. kills all possibly running memcached and memtier instances on their respectful VMs
#	5. populates all memcached instances
init() {
	rm -r $dst_folder_basename$subfolder
	mkdir $dst_folder_basename
	mkdir $dst_folder_basename$subfolder

	fix_ssh_keys

	start_all_machines

	get_memcached_private_ips

	command_for_memcached_kill_basic=" sudo service memcached stop "
	command_for_memcached_kill=" lsof -t -i:"${memcached_ports[0]}" | xargs kill -9 "
	command_for_memtier_kill=" kill -9 $(ps -ef | grep memtier | head -1 | awk -F " " '{print $2}') "

	sleep 60
	echo "                >> Woken up.."

	echo "                >> Clearing old processes and checking if connection was established..."
	connect_persistant_fast ${memcached[0]} "$command_for_memcached_kill_basic"
	echo "                >> Killed default memcached..."
	connect_persistant_fast ${memcached[0]} "$command_for_memcached_kill"
	echo "                >> Killed any memcached possibly running on port ${memcached_ports[0]} ..."
	connect_persistant_fast ${memtier[0]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[1]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[2]} "$command_for_memtier_kill"
	echo "                >> Killed any memtier processes ..."

	sleep 10

	populate_memcached
}

#############################################################################################################################
#############################################################################################################################
#############################################################################################################################

init

echo
echo "======================================================================================================================="
echo "======================================================WRITE ONLY======================================================="
echo "======================================================================================================================="
write_only_load
echo
echo "======================================================================================================================="
echo "======================================================READ ONLY========================================================"
echo "======================================================================================================================="
read_only_load

kill_all_memcached

stop_all_machines

echo "Done&Done."