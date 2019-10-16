# Kubenetes installation
## Building a simple Kubernetes master and nodes Ubuntu on 18

### Master
To build the master server just run the script with the parameter `build.sh master`.
Copy the join command to join the nodes to the cluster

### Node
To build the nodes just run the script without the parameter (master) `build.sh`.
Run the join command you copied from master server so that the node will be added to the cluster

### Check the nodes
To check if the node has joined the cluster run:
`kubectl get nodes`
