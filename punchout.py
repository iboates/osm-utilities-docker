import docker
from tqdm import tqdm


def is_already_punched_out(file_path, line_num):
    with open(file_path, 'r') as file:
        for current_line, line in enumerate(file, 1):
            if current_line == line_num:
                return line[0] == "#"
    return None  # Return None or raise an exception if the line does not exist


def punch_out(file_path, line_num):
    # Read the file and store lines in memory
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Replace the target line
    with open(file_path, 'w') as file:
        for i, line in enumerate(lines):
            if i == line_num:
                print(f"punching out line {i}: `{line.strip()}`")
                file.write(f"#{line}")
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
                print(f"punching in line {i}: `{line.strip()}`")
                file.write(line[1:])
            else:
                file.write(line)

ok_text = "osm2pgsql -- Import OpenStreetMap data into a PostgreSQL/PostGIS database"

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


for i in tqdm(range(start_line+1, end_line), total=end_line-start_line):

    # also check libexpat

    if is_already_punched_out("Dockerfile", i):
        continue
    punch_out("Dockerfile", i)
    image, build_logs = client.images.build(path=path_to_dockerfile, tag=f"{image_name}:{image_tag}", rm=True)
    run_result = client.containers.run("osm2pgsql:dev", "--help", stdout=True, stderr=True).decode("utf-8")
    if ok_text not in run_result:
        punch_in("Dockerfile", i)
