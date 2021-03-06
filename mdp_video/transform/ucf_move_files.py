"""
Move all the files into the appropriate train/test folders.

Should only run this file once!

Credits: the code was adapted from https://github.com/harvitronix/five-video-classification-methods
"""
import os
import os.path
import argparse
import shutil
from typing import Dict
import tqdm


def get_train_test_lists(root_dir: str, split_dir: str, version: str = "01") -> Dict:
    """
    Get train test split from file.
    """
    # Get our files based on version.
    test_file = os.path.join(split_dir, "testlist" + version + ".txt")
    train_file = os.path.join(split_dir, "trainlist" + version + ".txt")

    # Build the test list.
    with open(test_file) as fin:
        test_list = [os.path.join(root_dir, row.strip()) for row in list(fin)]

    # Build the train list. Extra step to remove the class index.
    with open(train_file) as fin:
        train_list = [row.strip() for row in list(fin)]
        train_list = [os.path.join(root_dir, row.split(" ")[0]) for row in train_list]

    # Set the groups in a dictionary.
    file_groups = {"train": train_list, "test": test_list}

    return file_groups


def move_files(file_groups: Dict, out_dir: str, to_same_folder: bool) -> None:
    """
    Move files to new locations.
    """
    # Do each of our groups.
    for group, videos in file_groups.items():
        for index, video in tqdm.tqdm(enumerate(videos), total=len(videos)):

            # Get the parts.
            parts = video.split("/")
            classname = parts[-2]
            filename = parts[-1]

            # Check if this class exists.
            if to_same_folder:
                video_path = os.path.join(out_dir, group)
            else:
                video_path = os.path.join(out_dir, group, classname, "{}_{}".format(classname, index))

            if not os.path.exists(video_path):
                os.makedirs(video_path)

            # Check if we have already moved this file, or at least that it
            # exists to move.
            if not os.path.exists(video):
                print(f"Can't find {video} to move. Skipping.")
                continue

            dest = os.path.join(video_path, filename)
            os.rename(video, dest)


if __name__ == "__main__":
    PARSER = argparse.ArgumentParser(
        "UCF extracting part 1.Go through each of our train/test text files and move the videos."
    )
    PARSER.add_argument("--root_dir", type=str, required=True, help="Path to data directory")
    PARSER.add_argument("--split_dir", type=str, required=True, help="Path to test/train split lists directory")
    PARSER.add_argument("--out_dir", type=str, required=True, help="Path to output directory")
    ARGS = PARSER.parse_args()

    # Get the videos in groups so we can move them.
    GROUP_LISTS = get_train_test_lists(root_dir=ARGS.root_dir, split_dir=ARGS.split_dir)

    # Move the files and remove previous data
    move_files(GROUP_LISTS, ARGS.out_dir, to_same_folder=False)
    shutil.rmtree(ARGS.root_dir)
