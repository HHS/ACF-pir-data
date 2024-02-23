def main():
    from . import createDirectories, configureDB, createRProj, installPackages
    createDirectories.main()
    configureDB.main()
    createRProj.main()
    installPackages.main()