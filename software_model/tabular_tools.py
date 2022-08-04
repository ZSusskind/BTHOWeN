import requests
import pandas as pd
import os
import subprocess

import numpy as np

datasets_df = pd.DataFrame(
    {
        "name": [
            "iris",
            "ecoli",
            "letter",
            "vehicle",
            "satimage",
            "vowel",
            "wine",
            "shuttle"
        ],
        "train_url": [
            "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/ecoli/ecoli.data",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/letter-recognition/letter-recognition.data",
            [
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xaa.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xab.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xac.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xad.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xae.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xaf.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xag.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xah.dat",
                "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/vehicle/xai.dat"
            ],
            "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/satimage/sat.trn",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/undocumented/connectionist-bench/vowel/vowel-context.data",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/wine/wine.data",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/shuttle/shuttle.trn.Z"
        ],
        "test_url": [
            "",
            "",
            "",
            "",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/satimage/sat.tst",
            "",
            "",
            "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/shuttle/shuttle.tst"
        ],
        "read_csv_kargs": [
            {},
            {
                'sep': '\s+',
                'usecols': list(range(1, 9)),
                'names': list(range(0, 8))
            },
            {},
            {
                'sep': '\s+'
            },
            {
                'sep': '\s+'
            },
            {
                'sep': '\s+'
            },
            {},
            {
                'sep': '\s+'
            }
        ],
        "transform": [
            lambda df: df,
            lambda df: df,
            lambda df: df[np.roll(range(0, 17), -1)].rename(
                columns={i: j for j, i in enumerate(np.roll(range(0, 17), -1))}),
            lambda df: df,
            lambda df: df,
            lambda df: df,
            lambda df: df[np.roll(range(0, 14), -1)].rename(
                columns={i: j for j, i in enumerate(np.roll(range(0, 14), -1))}),
            lambda df: df
        ],
        "test_split": [
            1./3,
            1./3,
            1./3,
            1./3,
            0.0,
            1./3,
            1./3,
            0.0
        ],
        "start_data_column": [
            0,
            0,
            0,
            0,
            0,
            3,
            0,
            0
        ],
        "end_data_column": [
            4,
            7,
            16,
            18,
            36,
            13,
            13,
            9
        ]
    }
)


def download_dataset(ds_name):
    row = datasets_df.loc[datasets_df['name'] == ds_name]

    # Check if dataset is in the table
    if len(row) == 0:
        raise ValueError(f'Dataset "{ds_name}" not found')

    # Check if folder aready exists
    if os.path.isdir(f"./datasets/{ds_name}"):
        # print("Already done")
        return

    os.makedirs(f"./datasets/{ds_name}", exist_ok=True)

    # Download dataset and store it
    if type(row['train_url'].values[0]) == list:
        kwargs = row['read_csv_kargs'].values[0]
        df = pd.concat([
            pd.read_csv(url, header=None, **kwargs)
            for url in row['train_url'].values[0]
        ])

        df.to_csv(f'./datasets/{ds_name}/{ds_name}.data',
                  header=None, index=False, sep=' ')
    else:
        f = f'./datasets/{ds_name}/{ds_name}.data'
        r = requests.get(row['train_url'].values[0], allow_redirects=True)
        open(f, 'wb').write(r.content)

        # Check if the training set table is compressed
        if row["train_url"].values[0].split(".")[-1] == "Z":
            os.rename(f, f + ".Z")
            subprocess.run(["uncompress", f + ".Z"])

        if row['test_url'].values[0] != "":
            r = requests.get(row['test_url'].values[0], allow_redirects=True)
            open(f'./datasets/{ds_name}/{ds_name}.test', 'wb').write(r.content)


def to_list_of_tuples(df, start, end):
    return [(r[start:end], int(r[end])) for r in df.to_numpy()]


def read_dataset(ds_name):
    row = datasets_df.loc[datasets_df['name'] == ds_name]
    read_csv_kargs, transform, test_split, start, end = row.iloc[0, 3:]

    df = transform(pd.read_csv(
        f'./datasets/{ds_name}/{ds_name}.data', header=None, **read_csv_kargs)).astype({end: 'category'})

    # Convert labels to integers
    df[end] = df[end].cat.codes

    # Shuffle rows and split into train and test sets
    df = df.sample(frac=1, random_state=123).reset_index(drop=True)

    test_end_row = int(np.floor(test_split*len(df)))

    test_df = df.iloc[0:test_end_row, :]
    train_df = df.iloc[test_end_row:, :]

    # Check for separate data set table
    if row["test_url"].values[0] != "":
        test_df = transform(pd.read_csv(
            f'./datasets/{ds_name}/{ds_name}.test', header=None, **read_csv_kargs)).astype({end: 'category'})
        test_df[end] = test_df[end].cat.codes

    train = to_list_of_tuples(train_df, start, end)
    test = to_list_of_tuples(test_df, start, end)

    return train, test


def get_dataset(ds_name):
    download_dataset(ds_name)

    return read_dataset(ds_name)
