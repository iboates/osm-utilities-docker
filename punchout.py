import docker
from tqdm import tqdm

def punch_out(file_path, line_num):
    # Read the file and store lines in memory
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Replace the target line
    with open(file_path, 'w') as file:
        for i, line in enumerate(lines):
            if i == line_num:
                print(f"punching out line {i}: `{line}`")
                file.write(f"#{line}" + '\n')
            else:
                file.write(line)


def punch_in(file_path, line_num):
    # Read the file and store lines in memory
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Replace the target line
    with open(file_path, 'w') as file:
        for i, line in enumerate(lines):
            if i == line_num:
                file.write(line[1:])
            else:
                file.write(line)


client = docker.from_env()

path_to_dockerfile = '.'

# Image name and tag
image_name = "osm2pgsql"
image_tag = "dev"


# Define the path to your Dockerfile
dockerfile_path = 'Dockerfile'

# Markers for the start and end of the section
start_marker = '# START PUNCHOUT'
end_marker = '# END PUNCHOUT'

# Initialize a flag to indicate if the current line is within the marked section
in_punchout_section = False

# Open and read the Dockerfile
with open(dockerfile_path, 'r') as file:
    for i, line in enumerate(file):
        # Check if the current line contains the start marker
        if start_marker in line:
            in_punchout_section = True
            start_line = i
            continue

        # Check if the current line contains the end marker
        if end_marker in line and in_punchout_section:
            end_line = i
            break


stop = False
i = 0
for i in tqdm(range(start_line+1, end_line), total=end_line-start_line):
    punch_out("Dockerfile", i)

    image, build_logs = client.images.build(path=path_to_dockerfile, tag=f"{image_name}:{image_tag}", rm=True)

    # Optionally, print build logs
    for line in build_logs:
        if 'stream' in line:
            print(line['stream'].strip())

    break

    # Execute the Docker build command
