#!/bin/sh

#### AUTOMATE REPO GENERATION
doRepos () {
    user=${1}
    echo "doRepos    user: $user"

    #### CHECK IS ROOT USER IF username IS AGUA
    if [ $whoami != "root" ] && [ $user = "agua" ]; then
        echo "doRepos    Must be 'root' to clone agua repos. Returning"
        return;
    fi

    repos=(agua aguatest aguatestdev bioapps bioappsdev biorepository biorepodev starcluster starclusterdev)

    for repo in ${repos[@]};
    do
        #### CLONE IT
        if [ -d $repo ]; then
            echo "clone    Repo exists already: $repo"
            echo "clone    Skipping clone"
            continue
        fi

        clone $user $repo;
        remote $user $repo;
        gitConfig $user $repo;
    done;
}

gitConfig () {
    user=${1}
    repo=${2}

    if [ ! $user ]; then
        echo "gitConfig    User argument not provided. Returning"
        return;
    fi

    if [ ! $repo ]; then
        echo "gitConfig    'repo' argument not provided. Returning"
        return;
    fi

    #### SKIP IF DIRECTORY IS MISSING
    if [ ! -d $repo ]; then
        echo "clone    Can't find repo: $repo. Returning"
        return
    fi

    #### UP DIR
    echo "cd $repo"
    cd $repo

    echo "gitConfig    Doing git config for user $user"
    if [ user = "syoung" ]; then
        git config --global user.name "Stuart Young"
        git config --global user.email "stuartpyoung@gmail.com"
        git config core.editor "emacs -nw" --global
    elif [ ! $user ]; then
        git config --global user.name "Agua Development Team"
        git config --global user.email "aguadev@gmail.com"
        git config core.editor "emacs -nw" --global
    fi

    #### DOWN DIR
    echo "cd .."
    cd ..

    echo "gitConfig    Completed"    
}

clone () {
    user=${1}
    repo=${2}
    echo "clone    user: $user"
    echo "clone    repo: $repo"    

    whoami=`whoami`

    #### CHECK IS ROOT USER IF username IS AGUA
    if [ $whoami != "root" ] && [ $user = "agua" ]; then
        echo "clone    Must be 'root' to clone agua repos. Returning"
        return;
    fi
    
    #### SKIP IF DIRECTORY ALREADY EXISTS
    if [ -d $repo ]; then
        echo "clone    Repo exists already: $repo"
        echo "clone    Skipping clone"
        return
    fi

    #### CLONE IT
    if [ $user = "agua" ]; then
        if [ $repo = "starclusterdev" ]; then
            echo "git clone git@github.com:agua/StarClusterDev starclusterdev"
            git clone "git@github.com:agua/StarClusterDev" starclusterdev
        elif [ $repo = "starcluster" ]; then
            echo "git clone git@github.com:agua/StarCluster starcluster"
            git clone "git@github.com:agua/StarCluster" starcluster
        else
            echo "git clone 'git@github.com:$user/$repo'"
            git clone "git@github.com:$user/$repo"
        fi
    elif [ $user = "syoung" ]; then
        echo "git clone 'git@github.com:$user/$repo'"
        git clone "git@github.com:$user/$repo"
    fi
}

remote () {
    user=${1}
    repo=${2}
    echo "remote user: $user"
    echo "remote repo: $repo"

    if [ ! $user ]; then
        echo "gitConfig    'user' argument not provided. Returning"
        return;
    fi

    if [ ! $repo ]; then
        echo "gitConfig    'repo' argument not provided. Returning"
        return;
    fi

    #### SKIP IF DIRECTORY IS MISSING
    if [ ! -d $repo ]; then
        echo "clone    Can't find repo: $repo. Returning"
        return
    fi

    #### CHECK IS ROOT USER IF username IS AGUA
    if [ $whoami != "root" ] && [ $user = "agua" ]; then
        echo "remote    Must be 'root' to clone agua repos. Returning"
        return;
    fi

    #### UP DIR
    echo "cd $repo"
    cd $repo

    #### REMOVE ORIGIN
    echo "git remote rm origin"
    git remote rm origin

    #### SET EDITOR
    echo "git config core.editor 'emacs -nw' --global"
    git config core.editor "emacs -nw" --global
    
    if [ $user = "agua" ]; then

        #echo "remote    CHECKING USER AGUA";

        #### SPECIAL CASES: STARCLUSTER AND STARCLUSTERDEV
        if [ $repo = "starclusterdev" ]; then
            echo "git remote add github git@github.com:agua/StarClusterDev"
            git remote add github "git@github.com:agua/StarClusterDev"
            echo "git remote add lin ssh://root@173.230.142.248/srv/git/public/agua/starclusterdev"
            git remote add lin "ssh://root@173.230.142.248/srv/git/public/agua/starclusterdev"
            echo "git remote add bit ssh://git@bitbucket.org/aguadev/starclusterdev.git"
            git remote add bit "ssh://git@bitbucket.org/aguadev/starclusterdev.git"
        elif [ $repo = "starcluster" ]; then
            echo "git remote add github git@github.com:agua/StarCluster"
            git remote add github "git@github.com:agua/StarCluster"
            echo "git remote add lin ssh://root@173.230.142.248/srv/git/public/agua/starcluster"
            git remote add lin "ssh://root@173.230.142.248/srv/git/public/agua/starcluster"
            echo "git remote add bit ssh://git@bitbucket.org/agua/starcluster.git"
            git remote add bit "ssh://git@bitbucket.org/agua/starcluster.git"
        else
            echo "git remote add github git@github.com:agua/$repo"
            echo "git remote add lin ssh://root@173.230.142.248/srv/git/public/agua/$repo"
            echo "git remote add bit ssh://git@bitbucket.org/aguadev/$repo.git"
            git remote add github "git@github.com:agua/$repo"
            git remote add lin "ssh://root@173.230.142.248/srv/git/public/agua/$repo"
            git remote add bit "ssh://git@bitbucket.org/aguadev/$repo.git"
        fi

    elif [ $user = "syoung" ]; then

        #echo "remote    CHECKING USER SYOUNG";

        echo "git remote add bit ssh://git@bitbucket.org/stuartpyoung/$repo.git"
        git remote add bit "ssh://git@bitbucket.org/stuartpyoung/$repo.git"
        echo "git remote add github git@github.com:syoung/$repo"
        git remote add github "git@github.com:syoung/$repo"
        echo "git remote add lin ssh://root@173.230.142.248/srv/git/private/syoung/$repo"
        git remote add lin "ssh://root@173.230.142.248/srv/git/private/syoung/$repo"
        
    fi

    #### DOWN DIR
    echo "cd .."
    cd ..
}        

#### SET REMOTES ONLY (NO CLONE)
remotes () {
    user=${1}
    echo "remotes user: $user"
    if [ ! $user ]; then
        echo "user not defined. Returning"
        return;
    fi

    repos=(agua aguadev aguatest aguatestdev bioapps bioappsdev biorepo biorepodev starcluster starclusterdev)

    for repo in ${repos[@]};
    do
        remote $user $repo;
    done;
}

#### TO DO:
#
#runCommand() {}
#
#isRoot () {
#    echo "DOING isRoot"
#    whoami=`whoami`
#    echo "whoami: $whoami"
#    if [ $whoami != "root" ] && [ $user = "agua" ]; then
#        return 1;
#    fi
#    
#    return 0;
#}

