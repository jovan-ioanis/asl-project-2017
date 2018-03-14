#!/bin/bash

suffix=.westeurope.cloudapp.azure.com

numberVMs=8
repetitions=3

resource_group=asl
nethzid=nikolijo
vm_name_base=foraslvms

vms=(1 2 3 4 5 6 7 8)

########################################################################################################
### MEMTIER:
########################################################################################################

memtier=(1 2 3)
memtier_instances_per_vm=2
memtier_threads=1
memtier_clients_pt=32


########################################################################################################
### MIDDLEWARE:
########################################################################################################

middleware_2=(4 5)
middleware_2_ports=(8080 8080)

middleware_1=(4 )
middleware_1_ports=(8080 )

middleware_threads=(32 8)


########################################################################################################
### MEMCACHED:
########################################################################################################

memcached_3=(6 7 8)
memcached_3_ports=(8080 8080 8080)

memcached_2=(6 7)
memcached_2_ports=(8080 8080)

private_ips_memtier=()
private_ips_middleware=()
private_ips_memcached=()

test_time=90 										# runtime of memtier in seconds
SET_ratio=0
GET_ratio=0

client_stats_file_basename="client_stats"
json_output_file_basename="json_output_file"
dst_folder_basename="data"
subfolder="/experiment_2k"
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
	for vm_id in "${middleware_2[@]}"
	do
		get_private_ip_one_vm $resource_group $vm_name_base$vm_id $vm_id
	done
	wait
}

get_memcached_private_ips() {
	echo "Fetching Memcached private ip addresses..."
	for vm_id in "${memcached_3[@]}"
	do
		get_private_ip_one_vm $resource_group $vm_name_base$vm_id $vm_id
	done
	wait
}

#########################################################################################################################################


# Starts memcached, middleware and memtier virtual machines, one by one
start_all_machines() {
	echo "Starting Memcached Virtual Machine(s)..."
	for vm_id in "${memcached_3[@]}"
	do
		echo "----------------------------"
		start_one_VM $resource_group $vm_name_base$vm_id
		echo "----------------------------"
		wait
	done
	echo "Memcached Virtual Machine(s) started.."
	echo "Starting Middleware Virtual Machine(s)..."
	for vm_id in "${middleware_2[@]}"
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
	for vm_id in "${middleware_1[@]}"
	do
		echo "++++++++++++++++++++++++++++"
		stop_one_VM $resource_group $vm_name_base$vm_id
		echo "++++++++++++++++++++++++++++"
		sleep 5
	done
	echo "Middleware Virtual Machine(s) stopped.."

	echo "Stopping Memcached Virtual Machines..."
	for vm_id in "${memcached_3[@]}"
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
run_all_memcached_3() {
	i=0
	for memcached_vm in "${memcached_3[@]}"
	do
		echo "                >> Running memcached on address "${private_ips_memcached[$i]}":"${memcached_3_ports[$i]}" ..."
		command_for_memcached=" memcached -t 1 -p "${memcached_3_ports[$i]}" "
		connect_fast $memcached_vm "$command_for_memcached" &

		sleep 10
		i=$((i+1))
	done
}

# param1: server count
copy_all_files_from_memcached() {
	copyFilesBackFromMemtier $nethzid $nethzid$vm_name_base${memcached_2[0]}$suffix
	connect_fast ${memcached_2[0]} " rm -r dstat* "

	copyFilesBackFromMemtier $nethzid $nethzid$vm_name_base${memcached_2[1]}$suffix
	connect_fast ${memcached_2[1]} " rm -r dstat* "

	if [ $1 -eq 3 ]
		then
			copyFilesBackFromMemtier $nethzid $nethzid$vm_name_base${memcached_3[2]}$suffix
			connect_fast ${memcached_3[2]} " rm -r dstat* "
	fi
}

# param1: server count
kill_all_memcached() {
	k=0
	for memcached_vm in "$memcached_2[@]"
	do
		command_for_memcached_kill=" lsof -t -i:"${memcached_2_ports[$k]}" | xargs kill -9 "
		connect_fast $memcached_vm "$command_for_memcached_kill"
		k=$((k+1))
	done	

	if [ $1 -eq 3 ]
		then
			command_for_memcached_kill=" lsof -t -i:"${memcached_3_ports[2]}" | xargs kill -9 "
			connect_fast ${memcached_3[2]} "$command_for_memcached_kill"
	fi
}


#########################################################################################################################
### Memtier
#########################################################################################################################

# Runs 2 memtier instances per memtier VM
# first one connected to first middleware, second one connected to second middleware
# param1: server count, param2: middleware count, param3: worker thread count, param4: repetition
run_all_memtiers_2() {
	for memtier_vm in "${memtier[@]}"
	do
		for j in `seq 1 1 $memtier_instances_per_vm`
		do		
			current_middleware=$((j-1))
			current_client_stat_file=$client_stats_file_basename"_inst"$j"_cpt"$memtier_clients_pt"_wt"$3"_rep"$4"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm"_server"$1"_mw"$2".log"
			current_json_output_file=$json_output_file_basename"_inst"$j"_cpt"$memtier_clients_pt"_wt"$3"_rep"$4"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm"_server"$1"_mw"$2".json"

			echo "                >> Connecting to middleware "${private_ips_middleware[$current_middleware]}":"${middleware_2_ports[$current_middleware]}" ..."

			command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_middleware[$current_middleware]}" \
								  --port="${middleware_2_ports[$current_middleware]}" \
								  --protocol=memcache_text --data-size=1024 \
								  --expiry-range=9999-10000 \
								  --key-maximum=10000 \
								  --ratio="$SET_ratio":"$GET_ratio"  \
								  --random-data \
								  --clients="$memtier_clients_pt" \
								  --threads="$memtier_threads" \
								  --test-time="$test_time" \
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


# Runs 2 memtier instances per memtier VM
# both instances connected to the same middleware
# param1: server count, param2: middleware count, param3: worker thread count, param4: repetition
run_all_memtiers_1() {
	for memtier_vm in "${memtier[@]}"
	do
		for j in `seq 1 1 $memtier_instances_per_vm`
		do
			current_client_stat_file=$client_stats_file_basename"_inst"$j"_cpt"$memtier_clients_pt"_wt"$3"_rep"$4"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm"_server"$1"_mw"$2".log"
			current_json_output_file=$json_output_file_basename"_inst"$j"_cpt"$memtier_clients_pt"_wt"$3"_rep"$4"_S"$SET_ratio"-G"$GET_ratio"_vm"$memtier_vm"_server"$1"_mw"$2".json"

			echo "                >> Connecting to middleware "${private_ips_middleware[0]}":"${middleware_1_ports[0]}" ..."

			command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_middleware[0]}" \
								  --port="${middleware_1_ports[0]}" \
								  --protocol=memcache_text --data-size=1024 \
								  --expiry-range=9999-10000 \
								  --key-maximum=10000 \
								  --ratio="$SET_ratio":"$GET_ratio"  \
								  --random-data \
								  --clients="$memtier_clients_pt" \
								  --threads="$memtier_threads" \
								  --test-time="$test_time" \
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


# Runs 2 middlewares
# param1: number of worker threads, param2: number of servers
run_middlewares_2() {

	if [ $2 -eq 3 ]
		then
			j=0
			for middleware_vm in "${middleware_2[@]}"
			do
				echo "                >> Connecting Middleware "${private_ips_middleware[$j]}":"${middleware_2_ports[$j]}" to "$2" servers..."
				command_for_middleware="java -jar "$jar_file_name" \
											 -l "${private_ips_middleware[$j]}" \
											 -p "${middleware_2_ports[$j]}" \
											 -m "${private_ips_memcached[0]}":"${memcached_3_ports[0]}" \
											  "${private_ips_memcached[1]}":"${memcached_3_ports[1]}" \
											  "${private_ips_memcached[2]}":"${memcached_3_ports[2]}" \
											 -t "$1" \
											 -s false"
				connect_fast $middleware_vm "$command_for_middleware" &
				j=$((j+1))
			done
			sleep 8
	fi

	if [ $2 -eq 2 ]
		then
			j=0
			for middleware_vm in "${middleware_2[@]}"
			do
				echo "                >> Connecting Middleware "${private_ips_middleware[$j]}":"${middleware_2_ports[$j]}" to "$2" servers..."
				command_for_middleware="java -jar "$jar_file_name" \
											 -l "${private_ips_middleware[$j]}" \
											 -p "${middleware_2_ports[$j]}" \
											 -m "${private_ips_memcached[0]}":"${memcached_2_ports[0]}" \
											  "${private_ips_memcached[1]}":"${memcached_2_ports[1]}" \
											 -t "$1" \
											 -s false"
				connect_fast $middleware_vm "$command_for_middleware" &
				j=$((j+1))
			done
			sleep 8
	fi
}


# Runs 1 middleware
# param1: number of worker threads, param2: number of servers
run_middlewares_1() {

	if [ $2 -eq 3 ]
		then
			j=0
			for middleware_vm in "${middleware_1[@]}"
			do
				echo "                >> Connecting Middleware "${private_ips_middleware[$j]}":"${middleware_1_ports[$j]}" to "$2" servers..."
				command_for_middleware="java -jar "$jar_file_name" \
											 -l "${private_ips_middleware[$j]}" \
											 -p "${middleware_1_ports[$j]}" \
											 -m "${private_ips_memcached[0]}":"${memcached_3_ports[0]}" \
											  "${private_ips_memcached[1]}":"${memcached_3_ports[1]}" \
											  "${private_ips_memcached[2]}":"${memcached_3_ports[2]}" \
											 -t "$1" \
											 -s false"
				connect_fast $middleware_vm "$command_for_middleware" &
				j=$((j+1))
			done
			sleep 8
	fi

	if [ $2 -eq 2 ]
		then
			j=0
			for middleware_vm in "${middleware_1[@]}"
			do
				echo "                >> Connecting Middleware "${private_ips_middleware[$j]}":"${middleware_1_ports[$j]}" to "$2" servers..."
				command_for_middleware="java -jar "$jar_file_name" \
											 -l "${private_ips_middleware[$j]}" \
											 -p "${middleware_1_ports[$j]}" \
											 -m "${private_ips_memcached[0]}":"${memcached_2_ports[0]}" \
											  "${private_ips_memcached[1]}":"${memcached_2_ports[1]}" \
											 -t "$1" \
											 -s false"
				connect_fast $middleware_vm "$command_for_middleware" &
				j=$((j+1))
			done
			sleep 8
	fi
}


# param1: server count, param2: middleware count, param3: worker count, param4: repetition
# Assumes that middlewares are killed before invoking this method
# Also, it assumes that there was sufficient time allowed to middlewares to dump all the logs
# Does the following:
# 	3. copies all log files from remote machine to local machine, to the folder indicated by client thread count, worker thread count and repetition
# 	4. deletes all logs from remote machine
copy_all_files_from_middleware_2() {
	i=1
	for middleware_vm in "${middleware_2[@]}"
	do
		folder_name="clientThreads_"$memtier_clients_pt"_workerThreads_"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2
		final_destination=$dst_folder_basename$subfolder"/middleware"$i"_outof_"$2"/"$folder_name

		rm -r $final_destination	
		mkdir -p $final_destination

		sleep 5

		copyFilesBackFromMiddleware $nethzid $nethzid$vm_name_base$middleware_vm$suffix "$final_destination"
		connect_fast $middleware_vm " rm -r logs dstat* ping* "

		sleep 5

		i=$((i+1))
	done	
}

# param1: server count, param2: middleware count, param3: worker count, param4: repetition
# Assumes that middlewares are killed before invoking this method
# Also, it assumes that there was sufficient time allowed to middlewares to dump all the logs
# Does the following:
# 	3. copies all log files from remote machine to local machine, to the folder indicated by client thread count, worker thread count and repetition
# 	4. deletes all logs from remote machine
copy_all_files_from_middleware_1() {
	i=1
	for middleware_vm in "${middleware_1[@]}"
	do
		folder_name="clientThreads_"$memtier_clients_pt"_workerThreads_"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2
		final_destination=$dst_folder_basename$subfolder"/middleware"$i"_outof_"$2"/"$folder_name

		rm -r $final_destination	
		mkdir -p $final_destination

		sleep 5

		copyFilesBackFromMiddleware $nethzid $nethzid$vm_name_base$middleware_vm$suffix "$final_destination"
		connect_fast $middleware_vm " rm -r logs dstat* ping* "

		sleep 5

		i=$((i+1))
	done	
}


#########################################################################################################################
### General
#########################################################################################################################

#param1: server count, param2: worker count
prepopulate_memcached_2() {
	echo "                >> Prepopulating memcached through middlewares.."

	echo "                >> Running all middlewares .."
	run_middlewares_2 $2 $1

	sleep 30

	for memtier_vm in "${memtier[@]}"
	do
		for j in `seq 1 1 $memtier_instances_per_vm`
		do		
			current_middleware=$((j-1))

			echo "                >> Connecting to middleware "${private_ips_middleware[$current_middleware]}":"${middleware_2_ports[$current_middleware]}" ..."

			command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_middleware[$current_middleware]}" \
								  --port="${middleware_2_ports[$current_middleware]}" \
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

	kill_middlewares_2
}

kill_middlewares_2() {
	echo "                >> Killing both middlewares only ... "
	i=1
	for middleware_vm in "${middleware_2[@]}"
	do
		echo "                >> Killing with killall... "

		connect_fast $middleware_vm "killall java"

		sleep 25

		connect_fast $middleware_vm " rm -r logs dstat* ping* "

		sleep 5

		i=$((i+1))
	done	
}

# param1: server count, param2: worker threads
prepopulate_memcached_1() {
	echo "                >> Prepopulating memcached through middlewares.."

	echo "                >> Running all middlewares .."
	run_middlewares_1 $2 $1

	sleep 30

	for memtier_vm in "${memtier[@]}"
	do
		for j in `seq 1 1 $memtier_instances_per_vm`
		do		
			current_middleware=$((j-1))

			echo "                >> Connecting to middleware "${private_ips_middleware[0]}":"${middleware_1_ports[0]}" ..."

			command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="${private_ips_middleware[0]}" \
								  --port="${middleware_1_ports[0]}" \
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

	kill_middlewares_1
}

kill_middlewares_1() {
	echo "                >> Killing middleware only ... "
	i=1
	for middleware_vm in "${middleware_1[@]}"
	do
		echo "                >> Killing with killall... "

		connect_fast $middleware_vm "killall java"

		sleep 25

		connect_fast $middleware_vm " rm -r logs dstat* ping* "

		sleep 5

		i=$((i+1))
	done	
}

# param1: middleware count
remove_jar_file() {

	if [ $1 -eq 2 ]
		then
			echo "                >> Removing jar file... "
			connect_fast ${middleware_2[0]} " rm -r dist/*.jar "
			connect_fast ${middleware_2[1]} " rm -r dist/*.jar "
	fi 

	if [ $1 -eq 1 ]
		then
			echo "                >> Removing jar file... "
			connect_fast ${middleware_1[0]} " rm -r dist/*.jar "
	fi	
}

# param1: server count, param2: middleware count, param3: worker threads, param4: repetition
run_remote_dstat() {
	echo "                >> Running dstat at "${memtier[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier1_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
	connect_fast ${memtier[0]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memtier[1]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier2_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
	connect_fast ${memtier[1]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memtier[2]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memtier3_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
	connect_fast ${memtier[2]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${middleware_1[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_middleware1_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
	connect_fast ${middleware_1[0]} "$command_for_dstat" > /dev/null &	

	echo "                >> Running dstat at "${memcached_2[0]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached1_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
	connect_fast ${memcached_2[0]} "$command_for_dstat" > /dev/null &

	echo "                >> Running dstat at "${memcached_2[1]}" .."
	command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached2_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
	connect_fast ${memcached_2[1]} "$command_for_dstat" > /dev/null &

	if [ $2 -eq 2 ]
		then
			echo "                >> Running dstat at "${middleware_2[1]}" .."
			command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_middleware2_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
			connect_fast ${middleware_2[1]} "$command_for_dstat" > /dev/null &
	fi

	if [ $1 -eq 3 ]
		then 
			echo "                >> Running dstat at "${memcached_3[2]}" .."
			command_for_dstat=" dstat -c -d -i -l -m -n -p -t -y --tcp --output dstat_memcached3_cpt"$memtier_clients_pt"_wt"$3"_S"$SET_ratio"-G"$GET_ratio"_rep"$4"_server"$1"_mw"$2".txt"
			connect_fast ${memcached_3[2]} "$command_for_dstat" > /dev/null &
	fi
}

# param1: server count, param2: middleware count
kill_dstats() {
	connect_fast ${memtier[0]} "pkill dstat" &>/dev/null &
	connect_fast ${memtier[1]} "pkill dstat" &>/dev/null &
	connect_fast ${memtier[2]} "pkill dstat" &>/dev/null &
	connect_fast ${middleware_1[0]} "pkill dstat" &>/dev/null &
	
	connect_fast ${memcached_2[0]} "pkill dstat" &>/dev/null &
	connect_fast ${memcached_2[1]} "pkill dstat" &>/dev/null &	

	if [ $1 -eq 3 ]
		then
			connect_fast ${memcached_3[2]} "pkill dstat" &>/dev/null &
	fi

	if [ $2 -eq 2 ]
		then
			connect_fast ${middleware_2[1]} "pkill dstat" &>/dev/null &
	fi
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

# param1: server count, param2: middleware count, param3: worker threads, param4: repetition
ping_test() {
	echo "                >> Ping test.."
	connect_fast ${memtier[0]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier1_cpt"$memtier_clients_pt"_wt"$2"_S"$SET_ratio"-G"$GET_ratio"_rep"$3"_server"$4"_mw"$5".txt"
	connect_fast ${memtier[0]} "ping -c 1 "${private_ips_middleware[0]}" " > $dst_folder_basename$subfolder"/ping_results_memtier2_cpt"$memtier_clients_pt"_wt"$2"_S"$SET_ratio"-G"$GET_ratio"_rep"$3"_server"$4"_mw"$5".txt"
	connect_fast ${middleware_1[0]} "ping -c 1 "${private_ips_memcached[0]}" " > $dst_folder_basename$subfolder"/ping_results_middleware1_cpt"$memtier_clients_pt"_wt"$2"_S"$SET_ratio"-G"$GET_ratio"_rep"$3"_server"$4"_mw"$5".txt"
	
	echo "                >> Ping test done."

	if [ $2 -eq 2 ]
		then
			connect_fast ${memtier[1]} "ping -c 1 "${private_ips_middleware[1]}" " > $dst_folder_basename$subfolder"/ping_results_memtier3_cpt"$memtier_clients_pt"_wt"$2"_S"$SET_ratio"-G"$GET_ratio"_rep"$3"_server"$4"_mw"$5".txt"
	fi

	if [ $1 -eq 3 ]
		then
			connect_fast ${memtier[2]} "ping -c 1 "${private_ips_memcached[2]}" " > $dst_folder_basename$subfolder"/ping_results_memtier4_cpt"$memtier_clients_pt"_wt"$2"_S"$SET_ratio"-G"$GET_ratio"_rep"$3"_server"$4"_mw"$5".txt"
	fi
}

#param1: server count, param2: middleware count, param3: worker count
one_iteration() {

	for rep in `seq 1 1 $repetitions`
	do

		echo "                 ==== SERVERS = "$1", MIDDLEWARE = "$2", WORKER COUNT = "$3", SET:GET = "$SET_ratio":"$GET_ratio", REPETITION = "$rep" ===="

		ping_test $1 $2 $3 $rep

		run_remote_dstat $1 $2 $3 $rep

		if [ $2 -eq 2 ]
			then
				run_middlewares_2 $3 $1
				sleep 30
				run_all_memtiers_2 $1 $2 $3 $rep

				kill_dstats $1 $2

				sleep 5

				for middleware_vm in "${middleware_2[@]}"
				do
					echo "                >> Killing with killall... "
					connect_fast $middleware_vm "killall java"
					sleep 10
				done
				copy_all_files_from_memtiers
				copy_all_files_from_memcached $1
				copy_all_files_from_middleware_2 $1 $2 $3 $rep
		fi 

		if [ $2 -eq 1 ]
			then
				run_middlewares_1 $3 $1
				sleep 30
				run_all_memtiers_1 $1 $2 $3 $rep

				kill_dstats $1 $2

				sleep 5

				for middleware_vm in "${middleware_1[@]}"
				do
					echo "                >> Killing with killall... "
					connect_fast $middleware_vm "killall java"
					sleep 10
				done
				copy_all_files_from_memtiers
				copy_all_files_from_memcached $1
				copy_all_files_from_middleware_1 $1 $2 $3 $rep
		fi

		sleep 4

	done

}

# param1: server count, param2: middleware count
start_load() {
	echo "                >> Starting load ..."

	for worker_count in "${middleware_threads[@]}"
	do
		SET_ratio=1
		GET_ratio=0

		one_iteration $1 $2 $worker_count

		SET_ratio=0
		GET_ratio=1

		one_iteration $1 $2 $worker_count

		SET_ratio=1
		GET_ratio=1

		one_iteration $1 $2 $worker_count
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
	command_for_memcached_kill=" lsof -t -i:"${memcached_3_ports[0]}" | xargs kill -9 "
	command_for_memtier_kill=" kill -9 $(ps -ef | grep memtier | head -1 | awk -F " " '{print $2}') "
	# command_for_middleware_kill=" kill -9 $(ps -ef | grep nikolijo | head -1 | awk -F " " '{print $2}') "
	command_for_middleware_kill="killall java"

	sleep 60
	echo "                >> Woken up.."

	echo "                >> Clearing old processes and checking if connection was established..."
	connect_persistant_fast ${memcached_3[0]} "$command_for_memcached_kill_basic"
	connect_persistant_fast ${memcached_3[1]} "$command_for_memcached_kill_basic"
	connect_persistant_fast ${memcached_3[2]} "$command_for_memcached_kill_basic"
	echo "                >> Killed default memcached..."
	connect_persistant_fast ${memcached_3[0]} "$command_for_memcached_kill"
	connect_persistant_fast ${memcached_3[1]} "$command_for_memcached_kill"
	connect_persistant_fast ${memcached_3[2]} "$command_for_memcached_kill"
	echo "                >> Killed any memcached possibly running on port ${memcached_3_ports[0]} ..."
	connect_persistant_fast ${memtier[0]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[0]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[1]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[1]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[2]} "$command_for_memtier_kill"
	connect_persistant_fast ${memtier[2]} "$command_for_memtier_kill"
	echo "                >> Killed any memtier processes ..."
	connect_persistant_fast ${middleware_2[0]} "$command_for_middleware_kill"
	connect_persistant_fast ${middleware_2[1]} "$command_for_middleware_kill"
	echo "                >> Killed any possible middleware process..."

	sleep 10

	connect_persistant_fast ${memtier[0]} "rm -r json* dstat* client_stats* ping*"
	connect_persistant_fast ${memtier[1]} "rm -r json* dstat* client_stats* ping*"
	connect_persistant_fast ${memtier[2]} "rm -r json* dstat* client_stats* ping*"
	connect_persistant_fast ${middleware_2[0]} "rm -r json* dstat* ping* logs "
	connect_persistant_fast ${middleware_2[1]} "rm -r json* dstat* ping* logs "
	connect_persistant_fast ${memcached_3[0]} "rm -r json* dstat* ping* "
	connect_persistant_fast ${memcached_3[1]} "rm -r json* dstat* ping* "
	connect_persistant_fast ${memcached_3[2]} "rm -r json* dstat* ping* "

	copyFilesToMachine $nethzid $nethzid$vm_name_base${middleware_2[0]}$suffix
	copyFilesToMachine $nethzid $nethzid$vm_name_base${middleware_2[1]}$suffix

	run_all_memcached_3
}


#############################################################################################################################
#############################################################################################################################
#############################################################################################################################

init

echo
echo "======================================================================================================================="
echo "======================================================  2 K  ======================================================="
echo "======================================================================================================================="

SET_ratio=10
GET_ratio=10

echo "********************* starting load *********************"

wt=32

num_mws=2
num_servers=3
prepopulate_memcached_2 $num_servers $wt
start_load $num_servers $num_mws

num_mws=2
num_servers=2
prepopulate_memcached_2 $num_servers $wt
start_load $num_servers $num_mws

echo "Stopping Middleware Virtual Machine 5..."
echo "++++++++++++++++++++++++++++"
stop_one_VM $resource_group $vm_name_base${middleware_2[1]}
echo "++++++++++++++++++++++++++++"
sleep 5

num_mws=1
num_servers=3
prepopulate_memcached_1 $num_servers $wt
start_load $num_servers $num_mws

num_mws=1
num_servers=2
prepopulate_memcached_1 $num_servers $wt
start_load $num_servers $num_mws

echo "********************* finished with load *********************"

num_servers=3
kill_all_memcached $num_servers

remove_jar_file $num_mws

stop_all_machines

echo "Done&Done."