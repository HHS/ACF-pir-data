def main():
    from . import createDirectories, configureDB, createRProj
    createDirectories.main()
    configureDB.main()
    createRProj.main()