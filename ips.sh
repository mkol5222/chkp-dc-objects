#!/bin/bash

# give list of random IP and uuid separated by :

function random_ips {
    for i in `seq 5`
    do
        # Create the filename
        IP=$(printf "192.168.%d.%d\n" "$((RANDOM % 256 ))" "$((RANDOM % 256 ))")
        ID=$(uuidgen)
        echo "$IP:$ID"
    done
}

# format as DC objects feed according to sk167210
#   https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk167210&partition=Basic&product=Quantum

random_ips | jq --raw-input -c '{ 
    name: "Custom_DC_Object_\(input_line_number)", 
    id: . | split(":") [1],
    "description": "Example for IPv4 addresses \(input_line_number)",
    ranges: [. | split(":") [0]] 
}' | jq --slurp '. as $ objects | {
    version: "1.0",
    "description": "Generic Data Center file example",
    "objects": $objects}'
