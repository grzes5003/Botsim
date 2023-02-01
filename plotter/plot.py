import itertools
from dataclasses import dataclass

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


@dataclass(repr=True)
class Res:
    ping_rcv: int
    ping_sent: int
    ping_passed: int
    msg_passed: int
    dest_unreach: int

    @classmethod
    def from_str(cls, _input: str):
        items = _input.split(';')
        return cls(dest_unreach=int(items[0][5:]),
                   ping_rcv=int(items[1][9:]),
                   ping_sent=int(items[2][10:]),
                   msg_passed=int(items[3][11:]),
                   ping_passed=0)


def read_logs(path: str) -> [Res]:
    _start_char = 'd'

    with open(path, 'r') as f:
        lines = f.readlines()

    lines = list(itertools.dropwhile(lambda line: line[0] != _start_char, lines))
    lines = [line.replace(' ', '').replace('\n', '') for line in lines]

    return [Res.from_str(line) for line in lines]


def obj2df(results: [Res]) -> pd.DataFrame:
    record = []
    for item in results:
        record.append([item.dest_unreach, item.ping_rcv, item.ping_sent, item.msg_passed])
    return pd.DataFrame(record, columns=['dest_unreach', 'ping_rcv', 'ping_sent', 'msg_passed'])


def plot_eff(df: pd.DataFrame):
    df['ping_rcv_r'] = df['ping_rcv'].diff()

    sns.set_theme(style="darkgrid")
    ax = sns.pointplot(x=df.index, y='ping_rcv_r', data=df)

    ax.set(ylabel='Diff ping received')
    ax.set_title('Efficiency based on used cores')
    ax.set(xlabel='Ticks')
    ax.legend(title='Size of problem [n]')

    plt.show()

    df['msg_passed_r'] = df['msg_passed'].diff()

    sns.set_theme(style="darkgrid")
    ax = sns.pointplot(x=df.index, y='msg_passed_r', data=df)

    ax.set(ylabel='Diff messages passed')
    ax.set_title('Efficiency based on used cores')
    ax.set(xlabel='Ticks')
    ax.legend(title='Size of problem [n]')

    plt.show()


if __name__ == '__main__':

    path_perf = '../resources/results/result01.log'
    res = read_logs(path_perf)
    df = obj2df(res)

    plot_eff(df)
    ...
