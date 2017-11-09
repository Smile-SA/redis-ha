# Redis Master, Slaves, Sentinels Statefulset Docker image

To be able to launch master, slave and sentinels in Kubernetes or OpenShift, we previously need to start a master, then slaves and sentinels, and to remove the master.

That image is able to startup in Statefulset mode.

The first redis server that starts is the Master. Others will be slaves. If master pod is down, so Sentinels elect an new Master.

That image can be used with Redis-Ellison: https://github.com/metal3d/redis-ellison

See [](project.yml) that is an example of making that image working as Statefulset.

# Rule them all with Ellison

Ellison is a project built by a Smile Lab temate, it's a proxy that allows usage of redis without the need of using Sentinels requests to find the master.

Simply give to Ellison the name of you Redis-HA service that is in the example project.yml

