#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 平台全局架构图（Architecture as Code，diagrams）

星级与《岗位总览》§五「技术栈差异」表 **逐格一致**。
节点评分 **仅** 使用句式：`能力₁（01★）·能力₂（02★）·能力₃（03★）·技术名（04★）`
（四个数字依次对应岗 01→04；不使用 `（a/b/c/d★）` 缩写。）

运行：pip install -r requirements-diagrams.txt && 系统安装 graphviz
     python3 diagrams_ai_platform_full_architecture.py

权威对照：../../岗位-技术提升/README-岗位总览与横向对比.md §五
"""

from diagrams import Diagram, Cluster, Edge

# --- 数据与存储 ---
from diagrams.onprem.client import Client
from diagrams.onprem.compute import Server
from diagrams.onprem.database import PostgreSQL
from diagrams.aws.storage import S3

# --- CI/CD 与研发 ---
from diagrams.onprem.ci import GithubActions

# --- K8s / 云原生 ---
from diagrams.k8s.group import Namespace
from diagrams.k8s.compute import Deployment
from diagrams.k8s.infra import Node as K8sWorkerNode

# --- 可观测 / 网络 / 算力抽象 ---
from diagrams.onprem.monitoring import Prometheus
from diagrams.onprem.network import Nginx
from diagrams.generic.compute import Rack

# --- MLOps / 应用侧 ---
from diagrams.onprem.mlops import Mlflow
from diagrams.programming.framework import FastAPI
from diagrams.programming.language import Python


# ---------------------------------------------------------------------------
# §五 技术栈 — 四岗星级（01, 02, 03, 04）
# ---------------------------------------------------------------------------
class T:
    K8S = (5, 2, 4, 5)
    GPU = (5, 1, 3, 3)
    INFER = (5, 2, 3, 4)
    DIST = (4, 1, 3, 1)
    MLOPS = (4, 2, 5, 3)
    SBX = (1, 1, 1, 5)
    LINUX_NS = (3, 1, 2, 5)
    WS = (4, 2, 1, 5)
    OBS = (5, 3, 4, 5)
    GO_RUST = (4, 2, 3, 5)
    LLM_APP = (2, 5, 1, 3)
    PROMPT = (1, 5, 1, 2)
    PROD = (2, 5, 2, 2)
    MGMT = (2, 5, 3, 2)


def flow4(w1, w2, w3, tech, t):
    """能力₁（01★）·能力₂（02★）·能力₃（03★）·技术（04★）"""
    a, b, c, d = t
    return "{}（{}★）·{}（{}★）·{}（{}★）·{}（{}★）".format(w1, a, w2, b, w3, c, tech, d)


def lbl(title, subtitle, *rating_lines):
    """rating_lines：每条为一整行 flow4 结果，多行则多技术栈。"""
    return "\n".join([title, subtitle] + list(rating_lines))


def main() -> None:
    graph_attr = {
        "pad": "0.5",
        "splines": "ortho",
        "nodesep": "0.50",
        "ranksep": "1.0",
        "fontsize": "13",
    }
    node_attr = {
        "fontsize": "11",
    }

    with Diagram(
        "AI Platform Full Architecture",
        show=False,
        direction="LR",
        filename="diagrams_ai_platform_full_architecture",
        outformat="png",
        graph_attr=graph_attr,
        node_attr=node_attr,
    ):
        # ========== 数据工程与存储 ==========
        with Cluster("数据工程与存储 (ETL & Storage)"):
            data_ingress = Client(
                lbl(
                    "数据源接入",
                    "行业 / 新闻 / 日志",
                    flow4("网关", "性能", "安全", "Go/Rust", T.GO_RUST),
                )
            )
            ingest_clean = Server(
                lbl(
                    "采集与清洗",
                    "采集编排 · 限速 · 重试 · 合规",
                    flow4("采集编排", "限速", "重试", "K8s", T.K8S),
                    flow4("单测", "规范", "交付", "MLOps", T.MLOPS),
                )
            )
            feature_store = PostgreSQL(
                lbl(
                    "特征存储",
                    "L1 时序 / 特征 raw",
                    flow4("分层", "副本", "调度", "K8s", T.K8S),
                    flow4("契约", "规则", "血缘", "MLOps", T.MLOPS),
                )
            )
            object_store = S3(
                lbl(
                    "对象存储中心",
                    "数据集快照 · 枢纽",
                    flow4("写入", "批次", "校验", "K8s", T.K8S),
                    flow4("指标", "日志", "SLO", "可观测", T.OBS),
                )
            )

            data_ingress >> ingest_clean
            ingest_clean >> feature_store
            ingest_clean >> object_store

        # ========== 模型研发与 MLOps ==========
        with Cluster("模型研发与 MLOps (Model R&D & MLOps)", direction="TB"):
            with Cluster("数据标注与对齐"):
                label_bench = Server(
                    lbl(
                        "人工标注台",
                        "意图提取 · 实时 WebSocket",
                        flow4("长连", "推送", "会话", "WebSocket", T.WS),
                    )
                )
                dialog_eval = Server(
                    lbl(
                        "多轮对话评测 / 预检",
                        "人机回环 · 门禁口径",
                        flow4("抽象", "指标", "价值", "产品", T.PROD),
                        flow4("离线", "漂移", "策略", "MLOps", T.MLOPS),
                    )
                )

            distributed_train = Rack(
                lbl(
                    "分布式训练",
                    "算力调度 · 并行 · 容错",
                    flow4("算力", "调度", "优化", "GPU", T.GPU),
                    flow4("并行", "扩展", "容错", "分布式训练", T.DIST),
                )
            )
            finetune = Server(
                lbl(
                    "专业微调",
                    "LoRA / 全参微调",
                    flow4("算力", "调度", "优化", "GPU", T.GPU),
                    flow4("实验", "编排", "制品", "MLOps", T.MLOPS),
                )
            )
            model_registry = Mlflow(
                lbl(
                    "模型注册中心",
                    "血缘 · 版本 · MLOps 审批",
                    flow4("注册", "血缘", "审批", "MLOps", T.MLOPS),
                )
            )

            label_bench >> dialog_eval
            feature_store >> label_bench
            object_store >> label_bench
            dialog_eval >> distributed_train
            distributed_train >> finetune
            finetune >> model_registry

        # ========== 研发效能与 CI/CD ==========
        with Cluster("研发效能与 CI/CD (DevOps & CI/CD)", direction="TB"):
            local_dev = Python(
                lbl(
                    "本地开发环境",
                    "IDE / Notebook",
                    flow4("网关", "性能", "安全", "Go/Rust", T.GO_RUST),
                )
            )
            eng_mgmt = Server(
                lbl(
                    "研发管理",
                    "规范 · 评测 · 交付",
                    flow4("协作", "决策", "组织", "管理", T.MGMT),
                    flow4("抽象", "指标", "价值", "产品", T.PROD),
                )
            )
            pipeline = GithubActions(
                lbl(
                    "流水线编排",
                    "CI/CD · 镜像构建",
                    flow4("构建", "测试", "发布", "MLOps", T.MLOPS),
                )
            )

            local_dev >> eng_mgmt >> pipeline

        # ========== 云原生底座与算力运行态 ==========
        with Cluster("云原生底座与算力运行态 (K8s & AI Infra)"):
            with Cluster("K8s 集群调度", direction="TB"):
                ns = Namespace(
                    lbl(
                        "命名空间与隔离",
                        "多租户 / 配额",
                        flow4("编排", "扩缩", "QoS", "K8s", T.K8S),
                        flow4("cgroup", "多租", "回收", "Linux ns", T.LINUX_NS),
                    )
                )
                workloads = Deployment(
                    lbl(
                        "工作负载",
                        "Deployment / Pod · 扩缩容",
                        flow4("编排", "弹性", "发布", "K8s", T.K8S),
                    )
                )
                isolation = K8sWorkerNode(
                    lbl(
                        "底层隔离技术",
                        "Linux ns · cgroup · 沙箱",
                        flow4("cgroup", "多租", "回收", "Linux ns", T.LINUX_NS),
                        flow4("隔离", "加固", "审计", "沙箱", T.SBX),
                    )
                )
                gpu_pool = Rack(
                    lbl(
                        "GPU 算力池",
                        "吞吐 · 批处理 · 大模型推理",
                        flow4("算力", "调度", "优化", "GPU", T.GPU),
                        flow4("吞吐", "批式", "并发", "大模型推理", T.INFER),
                    )
                )

                ns >> workloads >> isolation >> gpu_pool

            observability = Prometheus(
                lbl(
                    "可观测性中心",
                    "指标 · 日志 · Trace",
                    flow4("指标", "日志", "Trace", "可观测", T.OBS),
                )
            )

        # ========== 产品与网关 ==========
        with Cluster("产品微服务与网关 (Product & RAG Services)"):
            api_gateway = Nginx(
                lbl(
                    "统一网关接入",
                    "鉴权 · 多租户 · WebSocket",
                    flow4("网关", "弹性", "发布", "K8s", T.K8S),
                    flow4("长连", "推送", "会话", "WebSocket", T.WS),
                )
            )
            rag_engine = FastAPI(
                lbl(
                    "RAG 编排引擎",
                    "Prompt / 工作流 / LLM 应用",
                    flow4("RAG", "编排", "工具", "LLM应用", T.LLM_APP),
                    flow4("模板", "工作流", "迭代", "Prompt", T.PROMPT),
                )
            )
            biz_console = Client(
                lbl(
                    "业务控制台",
                    "产品管理 · Registry · 决策台",
                    flow4("抽象", "指标", "价值", "产品", T.PROD),
                    flow4("协作", "决策", "组织", "管理", T.MGMT),
                )
            )

        # ---------- 主干连线 ----------
        pipeline >> Edge(label="CI/CD 部署", color="darkgreen") >> workloads
        model_registry >> gpu_pool

        biz_console >> api_gateway >> rag_engine >> gpu_pool

        workloads >> Edge(style="dashed", color="gray") >> observability
        api_gateway >> Edge(style="dashed", color="gray") >> observability


if __name__ == "__main__":
    main()
