#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
产品功能视角 · 全局架构图（与 05_产品功能视角_全局架构与价值链.md 配套）

四大引擎节点标注：垂直专家个数（L3 最低 4+4+2=10）、专家名称摘要、Skill/状态 Skill（见 05 §3）。

运行：pip install -r requirements-diagrams.txt ；系统安装 graphviz
     python3 diagrams_product_feature_architecture.py
"""

from diagrams import Diagram, Cluster, Edge

from diagrams.onprem.client import Client
from diagrams.onprem.compute import Server
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.analytics import Dbt
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.monitoring import Prometheus
from diagrams.programming.framework import FastAPI


def main() -> None:
    graph_attr = {
        "pad": "0.5",
        "splines": "ortho",
        "nodesep": "0.45",
        "ranksep": "0.85",
        "fontsize": "13",
    }
    node_attr = {"fontsize": "11"}

    with Diagram(
        "Product Features · Global Architecture",
        show=False,
        direction="LR",
        filename="diagrams_product_feature_architecture",
        outformat="png",
        graph_attr=graph_attr,
        node_attr=node_attr,
    ):
        # ----- 用户触点 -----
        with Cluster("用户与研究触点"):
            console = Client("控制台与配置")
            track = Client("跟踪与提醒")
            feedback = Client("反馈与复盘")

        # ----- 产出 -----
        with Cluster("可交付产出"):
            research_card = Server("研究卡片与证据链")
            thesis_card = Server("Thesis 卡片与持仓快照")
            pools = Server("候选池与风险池")
            risk_out = Server("风险分与熔断建议")

        # ----- 四大引擎（专家规模与 Skill 见 05 §3 / L3 规约）-----
        with Cluster("四大产品能力引擎 (A/B/C/D)"):
            eng_a = Server(
                "A 极寒防御 · 4 垂直专家\n"
                "①存贷测谎 ②商誉预警 ③关联交易 ④质押跑路\n"
                "Skill域: 资产负债·商誉·供应链·治理"
            )
            eng_b = Server(
                "B 纵深进攻 · 4 垂直专家\n"
                "⑤剪刀差 ⑥S曲线 ⑦卖铲人 ⑧供给出清\n"
                "Skill: 四类剧本+失效条件"
            )
            eng_c = Server(
                "C 状态机 · 2 专家 + 6 状态 Skill\n"
                "⑨叙事漂移 ⑩情绪拥挤\n"
                "状态: VALID/WEAKEN/INVALID/DECAY/DRIFT/REBAL"
            )
            eng_d = Server(
                "D 进化反哺 · 1 套链路（非10专家）\n"
                "Skill: 反馈入库·版本·回灌·灰度"
            )

        # ----- 数据 -----
        with Cluster("数据与知识资产"):
            ingest = Dbt("采集与整理")
            knowledge = PostgreSQL("知识库与检索")

        # ----- 治理支撑 -----
        with Cluster("工程与治理支撑面"):
            eval_deploy = GithubActions("评测 · 灰度 · 回滚")
            observe = Prometheus("观测与回放")
            infer = FastAPI("推理与服务发布")

        # --- 主干：数据 -> 引擎 -> 产出 ---
        ingest >> knowledge
        knowledge >> eng_a
        knowledge >> eng_b
        knowledge >> eng_c
        knowledge >> eng_d

        eng_a >> risk_out
        eng_b >> pools
        eng_b >> research_card
        eng_c >> thesis_card
        eng_c >> track

        console >> eng_b
        console >> eng_c

        research_card >> track
        thesis_card >> track
        pools >> track
        risk_out >> track

        track >> feedback
        feedback >> eng_d
        eng_d >> knowledge

        # 支撑虚线
        for n in (eval_deploy, observe, infer):
            n >> Edge(style="dashed", color="gray") >> eng_b
        eval_deploy >> Edge(style="dashed", color="gray") >> eng_d


if __name__ == "__main__":
    main()
