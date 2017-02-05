# How-To

```bash
# start environment
$ vagrant up

# create dummy file test.box
$ touch test.box

# show vagrant ssh config
$ vagrant ssh-config

# upload box via scp
$ scp -P 2222 -i ~/.vagrant.d/insecure_private_key test.box vagrant@127.0.0.1:/tmp/test.box

# run bash via ssh (multiple times)
$ vagrant ssh -c "sudo /home/atlas/atlas.sh -b /tmp/test.box"
```
