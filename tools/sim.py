import sys
import os
import tomli
from pathlib import Path
# Check if an argument was provided
def dock_start
def simload(file):
    with open(file, "rb") as f:
        data = tomli.load(f)
    # Check that workspace exists, and make if it does not exist
    workspace_path = data["files"]["workspace"]
    complex_path = data["files"]["complex"]

    if not os.path.isdir(workspace_path) and os.path.exists(workspace_path):
        print(f'Workspace {workspace_path} is not a folder')
        return 1
    else if not os.path.isdir(workspace_path):
        os.makedirs(workspace_path)
    if not Path(data["files"]["complex"]).is_file():
        print(f'Workspace {complex_path} is not a valid file')
        return 1
    # Creat unique dir?
    # replace variables
    # call generate restraints
    # replace more variables
    # run with slurm
def cmd():
    if len(sys.argv) != 2:
        print(f"Provide one settings file for command line execution")
    else:
        simload(sys.argv[1])

if __name__ == "__main__":
    cmd()
