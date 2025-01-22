# Git configuration

Manage multiple git profiles. This is really useful, for instance,  when you develop your personal
projects alongside companies projects that required different email address configuration.  

You can create different `.gitconfig` files and load them in different places, for instance, when you
are in a certain git repository.

## How to use it.

Create a new configuration file (`.gitconfig` format) from the template file and name it however you want. 

Edit the new file and update the user configuration and/or add new configuration as required.

> Attention: If you already have a ~/.gitconfig don't forget to generate a backup copy to avoid unrecoverable damages.

Now, in the .gitconfig file, add a new `includeIf` section for the `gitdir` you want the new configuration to be
loaded, and add your new gitconfig file's path on the `path` directive.

```ini
[includeIf "gitdir:~/workspace/example-git-folder/"]
    path = ~/.dotfiles/gitconfig/example-config
```
