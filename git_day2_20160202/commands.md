Command to show all branches

`git branch`

Go to master branch

`git checkout master`

Update master branch

`git pull`

If you try to go to a branch doesn't exists

`git checkout geek`

Create a new branch from this point

`git checkout -b develop`

Create, add and commit

`touch newfile`

`git add newfile`

`git commit -m "better file"`

Modify file and commit again

Got to master and merge

`git checkout master` or `git checkout -`

See difference first

`git diff develop`

As well you can see what is gonna happen

`git merge --no-commit --no-ff test`

and abort if you don't like what you see

`git merge --abort`

You can merge and keep all the commits

`git merge develop`

or you can merge and rewrite the commit:

`got merge develop --squash`

As well you can work in something and need to change to other branch but you don't want to commit yet

`git stash`

When you are finish an back, you can start working again

`git stash apply`

