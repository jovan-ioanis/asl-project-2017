#!/bin/bash

suffix=.westeurope.cloudapp.azure.com

numberVMs=8
repetitions=3

resource_group=asl
nethzid=nikolijo
vm_name_base=foraslvms

vms=(1 2 3 4 5 6 7 8)

memtier=(1 2 3)
memtier_instances_per_vm=2 								# number of memtier instances per 1 memtier VM
memtier_threads=1 										# number of threads in memtier
# memtier_clients_pt=(64 52 42 32 28 22 15 8 5 1)			# number of virtual clients per thread in memtier 
memtier_clients_pt=(2 )			

middleware=(4 5)
middleware_ports=(8080 8080)
middleware_threads=(64 )								# number of worker threads per instance of Middleware

memcached=(6 7 8)
memcached_ports=(8080 8080 8080)

num_keys=(9 6 3 1)
#num_keys=(1 3 6 9)

private_ips_memtier=()
private_ips_middleware=()
private_ips_memcached=()

test_time=90 										# runtime of memtier in seconds
SET_ratio=0
GET_ratio=0

client_stats_file_basename="client_stats"
json_output_file_basename="json_output_file"
dst_folder_basename="data"
subfolder="/experiment_gets"
jar_file_name="dist/middleware-nikolijo.jar"
path_to_known_hosts="/home/jovan/.ssh/known_hosts"		# this should be changed according to one's computer
# path_to_known_hosts="/home/"$nethzid"/.ssh/known_hosts"		# this should be changed according to one's computer
middleware_output="logs/"

##############################################################################################################################################

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
copyFilesBackFromMemtier() {
	# scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2:$client_stats_file_basename* $1@$2:$output_file_basename* received_reports/
	scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2:$json_output_file_basename* $1@$2:dstat* $1@$2:ping* $1@$2:$client_stats_file_basename* $dst_folder_basename$subfolder
}

# param1: username, param2: public ip address or DNS name, param3: destination folder
# example: nikolijo@nikolijoforaslvms1.westeurope.cloudapp.azure.com
copyFilesBackFromMiddleware() {
	# scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2:$client_stats_file_basename* $1@$2:$output_file_basename* received_reports/
	scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" $1@$2:$middleware_output $1@$2:dstat* $1@$2:ping* "$3"
}

# param1: username, param2: public ip address or DNS name
# example: nikolijo@nikolijoforaslvms1.westeurope.cloudapp.azure.com
copyFilesToMachine() {
	scp -r -o "StrictHostKeyChecking no" -o "CheckHostIP no" "dist" $1@$2":."
}

get_memtier_private_ips() {
	echo "Fetching Memtier private ip addresses..."
	for vm_id in "${memtier[@]}"
	do
		get_private_ip_one_vm $resource_group $vm_name_base$vm_id $vm_id
	done
	wait
}

get_middleware_private_ips() {
	echo "Fetching Middleware private ip addresses..."
	for vm_id in "${middleware[@]}"
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

#########################################################################################################################################

# Starts memcached, middleware and memtier virtual machines, one by one
start_all_machines() {
	echo "Starting Memcached Virtual Machine(s)..."
	for vm_id in "${memcached[@]}"
	do
		echo "----------------------------"
		start_one_VM $resource_group $vm_name_base$vm_id
		echo "----------------------------"
		wait
	done
	echo "Memcached Virtual Machine(s) started.."
	echo "Starting Middleware Virtual Machine(s)..."
	for vm_id in "${middleware[@]}"
	do
		echo "----------------------------"
		start_one_VM $resource_group $vm_name_base$vm_id
		echo "----------------------------"
		wait
	done
	echo "Middleware Virtual Machine(s) started.."
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

# Stops memcached, middleware and memtier virtual machines, all in parallel, waits for all to finish
stop_all_machines() {
	echo "Stopping Memtier Virtual Machine(s)..."
	for vm_id in "${memtier[@]}"
	do
		echo "++++++++++++++++++++++++++++"
		stop_one_VM $resource_group $vm_name_base$vm_id
		echo "++++++++++++++++++++++++++++"
		sleep 5
	done
	echo "Memtier Virtual Machine(s) stopped.."

	echo "Stopping Middleware Virtual Machine(s)..."
	for vm_id in "${middleware[@]}"
	do
		echo "++++++++++++++++++++++++++++"
		stop_one_VM $resource_group $vm_name_base$vm_id
		echo "++++++++++++++++++++++++++++"
		sleep 5
	done
	echo "Middleware Virtual Machine(s) stopped.."

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

#########################################################################################################################
### Memcached
#########################################################################################################################

# Runs 1 memcached instance on 1 vm
run_all_memcached() {
	i=0
	for memcached_vm in "${memcached[@]}"
	do
		echo "                >> Running memcached on address "${private_ips_memcached[$i]}":"${memcached_ports[$i]}" ..."
		command_for_memcached=" memcached -t 1 -p "${memcached_ports[$i]}" "
		connect_fast $memcached_vm "$command_for_memcached" &

		sleep 10
		i=$((i+1))
	done
}

copy_all_files_from_memcached() {
	echo "                >> Copying files to local computer and removing from remote machines..."
	for memcached_vm in "${memcached[@]}"
	do
		copyFilesBackFromMemtier $nethzid $nethzid$vm_name_base$memcached_vm$suffix
		connect_fast $memcached_vm " rm -r dstat* "
	done	
}

kill_all_memcached() {
	k=0
	for memcached_vm in "$memcached[@]"
	do
		command_for_memcached_kill=" lsof -t -i:"${memcached_ports[$k]}" | xargs kill -9 "
		connect_fast $memcached_vm "$command_for_memcached_kill"
		k=$((k+1))
	done	
}


#########################################################################################################################
### Memtier
#########################################################################################################################

# Runs 2 memtier instances per memtier VM
# first one connected to first middleware, second one connected to second middleware
# param1: client per thread count, param2: worker thread count, param3: repetition, param4: "sharded" or "nonsharded", param5: num of keys
run_all_memtiers() {
	for memtier_vm in "${memtier[@]}"
	do
		for j in `seq 1 1 $memtier_instances_per_vm`
		do		
			current_middleware=$((j-1))
			current_client_stat_file=$client_stats_file_basename"_inst"$j"_cpt"$1"_wt"$2"_rep"$3"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm"_"$4"_keys"$5".log"
			current_json_output_file=$json_output_file_basename"_inst"$j"_cpt"$1"_wt"$2"_rep"$3"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm"_"$4"_keys"$5".json"

			echo "                >> Connecting to middleware "${private_ips_middleware[$current_middleware]}":"${middleware_ports[$current_middleware]}" ..."

			command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_middleware[$current_middleware]}" \
								  --port="${middleware_ports[$current_middleware]}" \
								  --protocol=memcache_text --data-size=1024 \
								  --expiry-range=9999-10000 \
								  --key-maximum=10000 \
								  --ratio=1:"$5"  \
								  --random-data \
								  --clients="$1" \
								  --threads="$memtier_threads" \
								  --test-time="$test_time" \
								  --multi-key-get="$5" \
								  --client-stats="$current_client_stat_file" \
								  --json-out-file="$current_json_output_file" "

			if [ $memtier_vm -eq 3 ]
				then
					if [ $j -eq $memtier_instances_per_vm ]
						then
							echo "                >> Running memtier instance "$j" on machine "$memtier_vm" ..." 
							connect_fast $memtier_vm "$command_for_memtier"
						else
							echo "                >> Running memtier instance "$j" on machine "$memtier_vm" ..."
							connect_fast $memtier_vm "$command_for_memtier" &
						fi
			else
				echo "                >> Running memtier instance "$j" on machine "$memtier_vm" ..."
				connect_fast $memtier_vm "$command_for_memtier" &
			fi
		done
	done
}

# no params
# copies all files from metiers in same "data" folder
# also tries to kill memtier processes, but all of them are always already finished by this point
copy_all_files_from_memtiers() {
	echo "                >> Copying files to local computer and removing from remote machine..."
	for memtier_vm in "${memtier[@]}"
	do
		connect_fast $memtier_vm "$command_for_memtier_kill"
		copyFilesBackFromMemtier $nethzid $nethzid$vm_name_base$memtier_vm$suffix
		connect_fast $memtier_vm " rm -r json* dstat* client_stats* "
	done	
}

#########################################################################################################################
### Middleware
#########################################################################################################################

# param1: number of worker threads, param2: "sharded" or "nonsharded"
run_all_middlewares() {
	l_sharded="sharded"
	l_nonsharded="nonsharded"

	echo "                >> Running middlewares! ... "

	if [ "$2" == "$l_sharded" ]
		then
			echo "                >> Running middleware in sharded mode ... "
			j=0
			for middleware_vm in "${middleware[@]}"
			do
				command_for_middleware="java -jar "$jar_file_name" \
											 -l "${private_ips_middleware[$j]}" \
											 -p "${middleware_ports[$j]}" \
											 -m "${private_ips_memcached[0]}":"${memcached_ports[0]}" \
											  "${private_ips_memcached[1]}":"${memcached_ports[1]}" \
											  "${private_ips_memcached[2]}":"${memcached_ports[2]}" \
											 -t "$1" \
											 -s true"
				connect_fast $middleware_vm "$command_for_middleware" &

				echo "                >> Connecting Middleware "${private_ips_middleware[$j]}":"${middleware_ports[$j]}" in "$2" mode to server..."

				j=$((j+1))
			done
			sleep 8
	else
		echo "                >> Running middleware in nonsharded mode ... "
		j=0
		for middleware_vm in "${middleware[@]}"
		do
			command_for_middleware="java -jar "$jar_file_name" \
										 -l "${private_ips_middleware[$j]}" \
										 -p "${middleware_ports[$j]}" \
										 -m "${private_ips_memcached[0]}":"${memcached_ports[0]}" \
										  "${private_ips_memcached[1]}":"${memcached_ports[1]}" \
										  "${private_ips_memcached[2]}":"${memcached_ports[2]}" \
										 -t "$1" \
										 -s false"
			connect_fast $middleware_vm "$command_for_middleware" &

			echo "                >> Connecting Middleware "${private_ips_middleware[$j]}":"${middleware_ports[$j]}" in "$2" mode to server..."

			j=$((j+1))
		done
		sleep 8
	fi	
}


# param1: number of client threads, param2: number of worker threads, param3: repetition, param4: "sharded" or "nonsharded", param5: num of keys
# Assumes that middlewares are killed before invoking this method
# Also, it assumes that there was sufficient time allowed to middlewares to dump all the logs
# Does the following:
# 	3. copies all log files from remote machine to local machine, to the folder indicated by client thread count, worker thread count and repetition
# 	4. deletes all logs from remote machine
copy_all_files_from_middleware() {
	i=1
	for middleware_vm in "${middleware[@]}"
	do
		folder_name="clientThreads_"$1"_workerThreads_"$2"_S"$SET_ratio"-G"$GET_ratio"_rep"$3"_"$4"_keys"$5
		final_destination=$dst_folder_basename$subfolder"/middleware"$i"/"$folder_name

		rm -r $final_destination	
		mkdir -p $final_destination

		sleep 5

		copyFilesBackFromMiddleware $nethzid $nethzid$vm_name_base$middleware_vm$suffix "$final_destination"
		connect_fast $middleware_vm " rm -r logs dstat* ping* "

		sleep 5

		i=$((i+1))
	done	
}


# no params
# Does the following:
#	1. kills middleware process and waits for it to finish dumping final logs
# 	2. deletes all logs from remote machine
# Used only for pre-population of memcached
kill_all_middlewares_only() {
	echo "                >> Killing all middlewares only ... "
	i=1
	for middleware_vm in "${middleware[@]}"
	do
		echo "                >> Killing with killall... "

		connect_fast $middleware_vm "killall java"

		sleep 25

		connect_fast $middleware_vm " rm -r logs dstat* ping* "

		sleep 5

		i=$((i+1))
	done	
}

#########################################################################################################################
### General
#########################################################################################################################

remove_jar_file() {
	echo "                >> Removing jar file... "
	connect_fast ${middleware[0]} " rm -r dist/*.jar "
	connect_fast ${middleware[1]} " rm -r dist/*.jar "
}

# param1: client per thread count, param2: worker threads, param3: repetition, param4: 1 for "r" or 0 for "w", param5: "sharded" or "nonsharded", param6: num of keys
run_remote_dstat() {
	echo "                >> Running dstat at "${memtier[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier1_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memtier[0]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memtier[1]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier2_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memtier[1]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memtier[2]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier3_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memtier[2]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${middleware[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_middleware1_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${middleware[0]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${middleware[1]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_middleware2_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${middleware[1]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memcached[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached1_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memcached[0]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memcached[1]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached2_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memcached[1]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memcached[2]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached3_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memcached[2]} "$command_for_dstat" > /dev/null &
}

kill_dstats() {
	connect_fast ${memtier[0]} "pkill dstat" &>/dev/null &
	connect_fast ${memtier[1]} "pkill dstat" &>/dev/null &
	connect_fast ${memtier[2]} "pkill dstat" &>/dev/null &
	connect_fast ${middleware[0]} "pkill dstat" &>/dev/null &
	connect_fast ${middleware[1]} "pkill dstat" &>/dev/null &
	connect_fast ${memcached[0]} "pkill dstat" &>/dev/null &
	connect_fast ${memcached[1]} "pkill dstat" &>/dev/null &
	connect_fast ${memcached[2]} "pkill dstat" &>/dev/null &
}

# the only purpose of this is to remove all SPOOFING warnings when ssh-ing to azure VMs
# this is relative to my own laptop, should be changed in according to one's location of known_hosts file
# and nethzid!
fix_ssh_keys() {
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms1.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms2.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms3.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms4.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms5.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms6.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms7.westeurope.cloudapp.azure.com
	ssh-keygen -f "$path_to_known_hosts" -R nikolijoforaslvms8.westeurope.cloudapp.azure.com
}

# param1: client per thread count, param2: worker threads, param3: repetition, param4: 1 for "r" or 0 for "w", param5: "sharded" or "nonsharded", param6: num of keys
ping_test() {
	echo "                >> Ping test.."
	connect_fast ${memtier[0]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier1_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memtier[0]} "ping -c 1 "${private_ips_middleware[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier2_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${memtier[1]} "ping -c 1 "${private_ips_middleware[1]}" " > $dst_folder_basename$subfolder"/ping_results_memtier3_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${middleware[0]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_middleware1_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	connect_fast ${middleware[1]} "ping -c 1 "${private_ips_memcached[1]}" " > $dst_folder_basename$subfolder"/ping_results_middleware2_cpt"$1"_wt"$2"_rep"$3"_"$4"_"$5"_keys"$6".txt"
	echo "                >> Ping test done."
}


prepopulate_memcached() {

	echo "                >> Prepopulating memcached through middlewares.."

	wt=64
	get_type_prepopulation="nonsharded"

	echo "                >> Running all middlewares .."
	run_all_middlewares $wt $get_type_prepopulation

	sleep 30

	for memtier_vm in "${memtier[@]}"
	do
		for j in `seq 1 1 $memtier_instances_per_vm`
		do		
			current_middleware=$((j-1))

			echo "                >> Connecting to middleware "${private_ips_middleware[$current_middleware]}":"${middleware_ports[$current_middleware]}" ..."

			command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_middleware[$current_middleware]}" \
								  --port="${middleware_ports[$current_middleware]}" \
								  --protocol=memcache_text --data-size=1024 \
								  --expiry-range=9999-10000 \
								  --key-maximum=10000 --key-pattern=S:S \
								  --random-data \
								  --clients=5 \
								  --threads=2 \
								  --test-time="$test_time" \
								  --ratio=1:0 "

			if [ $memtier_vm -eq 3 ]
				then
					if [ $j -eq $memtier_instances_per_vm ]
						then
							echo "                >> Running memtier instance "$j" on machine "$memtier_vm" ..." 
							connect_fast $memtier_vm "$command_for_memtier"
						else
							echo "                >> Running memtier instance "$j" on machine "$memtier_vm" ..."
							connect_fast $memtier_vm "$command_for_memtier" &
						fi
			else
				echo "                >> Running memtier instance "$j" on machine "$memtier_vm" ..."
				connect_fast $memtier_vm "$command_for_memtier" &
			fi
		done
	done

	sleep 15

	kill_all_middlewares_only
}

# no params
start_load() {
	echo "                >> Starting load ..."

	echo "                >> Before prepopulation ..."
	prepopulate_memcached
	echo "                >> After prepopulation ..."

	get_type="sharded"

	for client_count in "${memtier_clients_pt[@]}"
	do
		for worker_count in "${middleware_threads[@]}"
		do
			for keys in "${num_keys[@]}"
			do
				for rep in `seq 1 1 $repetitions`
				do

					echo "                 ==== THREAD COUNT = "$client_count", WORKER COUNT = "$worker_count", TYPE = "$get_type", KEYS = "$keys", REPETITION = "$rep" ===="

					ping_test $client_count $worker_count $rep $GET_ratio $get_type $keys

					run_remote_dstat $client_count $worker_count $rep $GET_ratio $get_type $keys

					run_all_middlewares $worker_count $get_type
					sleep 30
					run_all_memtiers $client_count $worker_count $rep $get_type $keys

					kill_dstats
					sleep 5

					for middleware_vm in "${middleware[@]}"
					do
						echo "                >> Killing with killall... "
						connect_fast $middleware_vm "killall java"
						sleep 10
					done

					copy_all_files_from_memtiers
					copy_all_files_from_memcached
					copy_all_files_from_middleware $client_count $worker_count $rep $get_type $keys
					sleep 5

				done
			done			
		done
	done

	prepopulate_memcached
	
	get_type="nonsharded"

	for client_count in "${memtier_clients_pt[@]}"
	do
		for worker_count in "${middleware_threads[@]}"
		do
			for keys in "${num_keys[@]}"
			do
				for rep in `seq 1 1 $repetitions`
				do

					echo "                 ==== THREAD COUNT = "$client_count", WORKER COUNT = "$worker_count", TYPE = "$get_type", KEYS = "$keys", REPETITION = "$rep" ===="

					ping_test $client_count $worker_count $rep $GET_ratio $get_type $keys

					run_remote_dstat $client_count $worker_count $rep $GET_ratio $get_type $keys

					run_all_middlewares $worker_count $get_type
					sleep 30
					run_all_memtiers $client_count $worker_count $rep $get_type $keys

					kill_dstats
					sleep 5

					for middleware_vm in "${middleware[@]}"
					do
						echo "                >> Killing with killall... "
						connect_fast $middleware_vm "killall java"
						sleep 10
					done

					copy_all_files_from_memtiers
					copy_all_files_from_memcached
					copy_all_files_from_middleware $client_count $worker_count $rep $get_type $keys
					sleep 5

				done
			done			
		done
	done
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

	# rm -r build/ dist/ 
	# ant -f build.xml

	fix_ssh_keys

	# start_all_machines

	get_memcached_private_ips
	get_middleware_private_ips

	command_for_memcached_kill_basic=" sudo service memcached stop "
	command_for_memcached_kill=" lsof -t -i:"${memcached_ports[0]}" | xargs kill -9 "
	command_for_memtier_kill=" kill -9 $(ps -ef | grep memtier | head -1 | awk -F " " '{print $2}') "
	# command_for_middleware_kill=" kill -9 $(ps -ef | grep nikolijo | head -1 | awk -F " " '{print $2}') "
	command_for_middleware_kill="killall java"

	sleep 60
	echo "                >> Woken up.."

	echo "                >> Clearing old processes and checking if connection was established..."
	connect_persistant_fast ${memcached[0]} "$command_for_memcached_kill_basic"
	connect_persistant_fast ${memcached[1]} "$command_for_memcached_kill_basic"
	connect_persistant_fast ${memcached[2]} "$command_for_memcached_kill_basic"
	echo "                >> Killed default memcached..."
	connect_persistant_fast ${memcached[0]} "$command_for_memcached_kill"
	connect_persistant_fast ${memcached[1]} "$command_for_memcached_kill"
	connect_persistant_fast ${memcached[2]} "$command_for_memcached_kill"
	echo "                >> Killed any memcached possibly running on port ${memcached_ports[0]} ..."
	connect_persistant_fast ${memtier[0]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[0]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[1]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[1]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[2]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[2]} "$command_for_memtier_kill"
	echo "                >> Killed any memtier processes ..."
	connect_persistant_fast ${middleware[0]} "$command_for_middleware_kill"
	connect_persistant_fast ${middleware[1]} "$command_for_middleware_kill"
	echo "                >> Killed any possible middleware process..."

	sleep 10

	connect_persistant_fast ${memtier[0]} "rm -r json* dstat* client_stats* ping*"
	connect_persistant_fast ${memtier[1]} "rm -r json* dstat* client_stats* ping*"
	connect_persistant_fast ${memtier[2]} "rm -r json* dstat* client_stats* ping*"
	connect_persistant_fast ${middleware[0]} "rm -r json* dstat* ping* logs "
	connect_persistant_fast ${middleware[1]} "rm -r json* dstat* ping* logs "
	connect_persistant_fast ${memcached[0]} "rm -r json* dstat* ping* "
	connect_persistant_fast ${memcached[1]} "rm -r json* dstat* ping* "
	connect_persistant_fast ${memcached[2]} "rm -r json* dstat* ping* "

	copyFilesToMachine $nethzid $nethzid$vm_name_base${middleware[0]}$suffix
	copyFilesToMachine $nethzid $nethzid$vm_name_base${middleware[1]}$suffix

	run_all_memcached
}


#############################################################################################################################
#############################################################################################################################
#############################################################################################################################

init

echo
echo "======================================================================================================================="
echo "======================================================READ ONLY======================================================="
echo "======================================================================================================================="

SET_ratio=0
GET_ratio=10
echo "********************* starting load *********************"
start_load
echo "********************* finished with load *********************"
kill_all_memcached

remove_jar_file

stop_all_machines

echo "Done&Done."
