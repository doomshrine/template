import re
import subprocess

def trim_semver(semver):
    # Remove the leading 'v' if present
    version = semver.lstrip('v')

    # Extract the MAJOR and MINOR components using regex
    match = re.match(r'^(\d+)\.(\d+)', version)
    if match:
        major = match.group(1)
        minor = match.group(2)
        return f'{major}.{minor}'
    else:
        return None

def define_env(env):
    "Hook function"

    @env.macro
    def git_version():
        "Return git version"
        try:
            # check if we are in tag, else return branch name
            output = subprocess.check_output(['git', 'describe', '--exact-match', '--tags', 'HEAD']).strip()
            version = output.decode('utf-8')
            return trim_semver(version)
        except subprocess.CalledProcessError:
            return "dev"
