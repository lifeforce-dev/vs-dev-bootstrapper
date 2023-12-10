import os
import subprocess

class GitHelper:
    @staticmethod
    def is_repo_path_valid(repo_path):
        """Check if the path is a valid Git repository."""
        if not os.path.exists(repo_path):
            return False

        git_dir = os.path.join(repo_path, '.git')
        return os.path.isdir(git_dir)

    @staticmethod
    def run_git_command(repo_path, command):
        """Run a git command in the given repository path and return the output."""
        try:
            result = subprocess.run(
                ["git"] + command,
                cwd=repo_path,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error running git command: {e.stderr}")
            return None

    @staticmethod
    def clone(repo_path, repo_url):
        """Clone a repository into the given path."""
        if not os.path.exists(repo_path):
            os.makedirs(repo_path, exist_ok=True)
        return GitHelper.run_git_command(repo_path, ["clone", repo_url, repo_path])

    @staticmethod
    def fetch(repo_path):
        """Fetch updates from the remote repository."""
        return GitHelper.run_git_command(repo_path, ["fetch"])

    @staticmethod
    def checkout(repo_path, branch):
        """Checkout a specific branch in the given repository."""
        return GitHelper.run_git_command(repo_path, ["checkout", branch])

    @staticmethod
    def reset_hard(repo_path):
        """Reset the given repository to the last commit, discarding all changes."""
        return GitHelper.run_git_command(repo_path, ["reset", "--hard"])

    @staticmethod
    def pull(repo_path):
        """Pull updates from the remote repository into the given path."""
        return GitHelper.run_git_command(repo_path, ["pull"])

    @staticmethod
    def is_current_branch(repo_path, branch_name):
        """Check if the current branch of the given repository matches the given branch name."""
        current_branch = GitHelper.run_git_command(repo_path, ["rev-parse", "--abbrev-ref", "HEAD"]).strip()
        return current_branch == branch_name

# Example usage
if __name__ == "__main__":
    repo_path = "/path/to/your/repo"
    repo_url = "https://github.com/user/repo.git"

    if GitHelper.is_repo_path_valid(repo_path):
        # Perform Git operations on existing repository
        GitHelper.fetch(repo_path)
        # ... other Git operations
    else:
        # Clone the repository as the path doesn't exist or isn't a Git repo
        GitHelper.clone(repo_path, repo_url)