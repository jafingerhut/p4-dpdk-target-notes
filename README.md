# P4 DPDK target notes


## Build the DPDK software switch

System tested: Ubuntu 20.04

To build the DPDK software switch, follow the README from the
[p4-dpdk-target](https://github.com/p4lang/p4-dpdk-target) Github
repository.  Alternately, you can run the script shown below.  Running
this script downloads about 1 GB of files from Github, and takes
approximately 45 minutes on a 2015 era MacBook Pro running an Ubuntu
20.04 VM in VirtualBox.

```bash
# Go to the root directory of your clone of this repository:
cd p4-dpdk-target-notes
./scripts/install-dpdk-sde-v1.sh |& tee log-install-dpdk-sde-v1-out.txt
```


## Compile the P4 program

There is a very simple L1 switch based on PSA architecture in the file
`l1switch/main.p4`.

Before building the P4 code, you must install the open source P4
compiler [p4lang/p4c](https://github.com/p4lang/p4c).

To compile the P4 program:

```bash
cd l1switch
./build.sh
```

Running the commands above will cause these files to be created:

- `main.spec`: the pipeline config
- `main.bfrt.json`: the bfrt/tdi config
- `main.pb.txt`: the P4Runtime P4Info file
- `context.json`: pipeline context file


## Run the DPDK software switch


### Prepare port config

We need to configure the DPDK software switch with how many ports it
has, what their port numbers are from the perspective of the P4 code
running on the DPDK software switch, and which physical or virtual
Ethernet ports they are connected to.

how to connect to ports. here is the json
schema for port config:

TODO: Why is there a "port_dir" configuration?

TODO: If a port is configured with "port_dir" equal to "in", does that
mean that the DPDK software switch can only receive packets from that
port, and is not able to send packets out that port?  What happens if
the P4 program attempts to send a packet to that port?

TODO: If a port is configured with "port_dir" equal to "out", does
that mean that the DPDK software switch will never receive packets
from that port?  What if some software or device on the other end of
that port sends a packet to it?  Will it simply not be delivered as an
input packet to the DPDK software switch, and simply be discarded?

TODO: What do the different values of "port_type" mean?  Do all
possible combinations of "port_dir" and "port_type" make sense?  Are
some combinations illegal and should never be part of a correct
configuration?

```jsonc
{
    "ports": [
        {
            "dev_port": 0, // The port ID
            "port_name": "", // The port name, will create a tap port with this name if "port_type" is "tap"
            "mempool_name": "", // The DPDK memory pool name, default will be "MEMPOOL0"
            "pipe_name": "", // The pipeline for this port, will be "p4_pipeline_name" in the switch config in next section.
            "port_dir": "", // "default", "in", or "out"
            "port_in_id": 0, // required when port_dir is "default" or "in"
            "port_out_id": 0, // required when port_dir is "default" or "out"
            "port_type": "", // "tap", "link", "source", or "sink"
            // required when port type is "tap"
            "tap_port_attributes": {
                "mtu": 1500
            },
            // required when port type is "link"
            "link_port_attributes": {
                "pcie_bdf": "", // BDF: bus, devece, function
                "dev_args": "",
                "dev_hotplug_enabled": 0
            },
            // required when port type is "source"
            "source_port_attributes": {
                "file_name": ""
            },
            // required when port type is "sink"
            "sink_port_attributes": {
                "file_name": ""
            }
        }
    ]
}
```

Here is an example for L1 switch which contains only two ports with id 0 and 1:

```json
{
    "ports": [
        {
            "dev_port": 0,
            "port_name": "veth0",
            "mempool_name": "MEMPOOL0",
            "pipe_name": "pipe",
            "port_dir": "default",
            "port_in_id": 0,
            "port_out_id": 0,
            "port_type": "tap",
            "tap_port_attributes": {
                "mtu": 1500
            }
        },
        {
            "dev_port": 1,
            "port_name": "veth1",
            "mempool_name": "MEMPOOL0",
            "pipe_name": "pipe",
            "port_dir": "default",
            "port_in_id": 1,
            "port_out_id": 1,
            "port_type": "tap",
            "tap_port_attributes": {
                "mtu": 1500
            }
        }

    ]
}
```


### Prepare switch config

You also need to create a switch config file to tell the switch where to load the pipeline
and port config, here we provide a simple switch config:

```json
{
    "chip_list": [
        {
            "id": "asic-0",
            "chip_family": "dpdk",
            "instance": 0
        }
    ],
    "instance": 0,
    "p4_devices": [
        {
            "device-id": 0,
            "eal-args": "dummy -n 4 -c 7",
            "mempools": [
                {
                    "name": "MEMPOOL0",
                    "buffer_size": 2304,
                    "pool_size": 1024,
                    "cache_size": 256,
                    "numa_node": 0
                }
	    ],
            "p4_programs": [
                {
                    "program-name": "l1switch",
                    "sai_default_init": false,
                    "bfrt-config": "Absolute path to main.bfrt.json",
                    "port-config": "Absolute path to ports.json",
                    "p4_pipelines": [
                        {
                            "p4_pipeline_name": "pipe",
			    "core_id": 1,
			    "numa_node": 0,
                            "context": "Absolute path to context.json",
                            "config": "Absolute path to main.spec",
                            "pipe_scope": [
                                0
                            ],
                            "path": "Absolute path to where you pit pipeline configs"
                        }
                    ]
                }
            ]
        }
    ]
}
```

Modify the path to the correct file and save it(e.g. switch_config.json)


### Start the switch

To start the switch, run the following script:

```bash
# Basic environment variables we need
source ../scripts/setup.bash

# For security reason, the PATH and LD_LIBRARY_PATH won't pass to root user even if we use "sudo -E"
# We must pass them in sudo to make sure it is correct.
sudo -E PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH ../scripts/set_hugepages.sh
sudo -E PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH $SDE_INSTALL/bin/bf_switchd --install-dir $SDE_INSTALL --conf switch_config.json
```


### Enable the pipeline

After started the switch, you need to enable the pipeline first before processing any
packets:

```text
bfshell> bfrt_python
In [1]: bfrt
------> bfrt()
Available symbols:
dump                 - Command
info                 - Command
l1switch             - Node
port                 - Node


bfrt> l1switch.enable
----> l1switch.enable()
```


### Send some traffic between ports

One way to test the pipeline with `TAP` ports is to use scapy and tcpdump

For example, start a tcpdump to dump packets from `veth1`

```bash
sudo tcpdump -i veth1 -vvv
```

And send few packets to veth0 by using Scapy (with root privileged)

```python
from scapy.all import *
pkt = Ether() / IP() / UDP() / "Hello world"
sendp(pkt, iface='veth0')
```

Another way is to create network namespace and move TAP ports to network namespaces.

```bash
sudo ip netns add h1
sudo ip netns add h2
sudo ip link set netns h1 dev veth0
sudo ip link set netns h2 dev veth1
sudo ip netns exec h1 ip addr add 10.0.0.1/24 dev veth0
sudo ip netns exec h2 ip addr add 10.0.0.2/24 dev veth1
sudo ip netns exec h1 ip link set veth0 up
sudo ip netns exec h2 ip link set veth1 up
ip netns exec h1 ping 10.0.0.2

# Cleanup
ip netns del h1
ip netns del h2
```


## Start the switch in container

We can also start the switch in a container, first is to build the container image:

```bash
docker build -t p4-dpdk .
```

And we can start container:

```bash
docker run -it --rm --privileged -v /dev/hugepages:/dev/hugepages p4-dpdk:latest
```

Note that p4-dpdk-target requries Hugepage setup, so we need to mount hugepage to the container
and set privileged mode (also required for creating TAP port)

You can mount/place your config(.spec/.bfrt.json/context.json/ports.json) to the container and start the switch
as mentioned in previous section.
