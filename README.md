ekyoserver-d
============

For now, this is an experiment of a plugin based architecture in D.

It is intended to expose a web API and generate client code to use it.
All of this should be done at compile time.

For now it is dependant on redis and mongo.

the priority for now is to have a working generated web API.


To compile the project
----------------------
note that you must first have dub installed. You may have to run dub multiple times for it to fetch dependencies appropriately for sub-dependencies... running dub again afterwards will compile and run the project.

    sudo apt-get install -y libevent-dev libev-dev libssl-dev
    git clone git@github.com:ekyo/ekyoserver-d.git
    cd ekyoserver-d
    dub
    dub
