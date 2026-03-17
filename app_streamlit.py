import streamlit as st
from pathlib import Path
from src.pipeline import Pipeline, max_config
from src.questions_processing import QuestionsProcessor
import json
import logging
import sys
from datetime import datetime
import os

# 配置日志系统 - 将所有日志输出到 .log 文件夹
log_dir = Path(".log")
log_dir.mkdir(exist_ok=True)

# 创建日志文件名（带时间戳）
log_filename = log_dir / f"app_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

# 配置根日志记录器
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename, encoding='utf-8'),
        logging.StreamHandler(sys.stdout)  # 同时输出到控制台
    ]
)

logger = logging.getLogger(__name__)
logger.info("=" * 60)
logger.info(f"应用程序启动 - 日志文件: {log_filename}")
logger.info("=" * 60)

# 配置其他模块的日志记录器
logging.getLogger('src').setLevel(logging.INFO)
logging.getLogger('src.pipeline').setLevel(logging.INFO)
logging.getLogger('src.questions_processing').setLevel(logging.INFO)

# 你可以让 root_path 固定，也可以让用户输入
root_path = Path("data/stock_data")
logger.info(f"初始化 Pipeline，数据路径: {root_path}")
pipeline = Pipeline(root_path, run_config=max_config)
logger.info("Pipeline 初始化完成")

st.set_page_config(page_title="RAG Challenge 2", layout="wide")

# 页面标题
st.markdown("""
<div style='background: linear-gradient(90deg, #7b2ff2 0%, #f357a8 100%); padding: 20px 0; border-radius: 12px; text-align: center;'>
    <h2 style='color: white; margin: 0;'>🚀 RAG Challenge 2</h2>
    <div style='color: #fff; font-size: 16px;'>基于深度RAG系统，由RTX 5080 GPU加速 | 支持多公司年报问答 | 向量检索+LLM推理+GPT-4o</div>
</div>
""", unsafe_allow_html=True)

# 创建两列布局：左侧主内容区，右侧查询设置
col1, col2 = st.columns([2, 1])

# 右侧查询设置区
with col2:
    st.header("查询设置")
    # 仅单问题输入
    user_question = st.text_area("输入问题", "请简要总结中芯国际公司所处的行业地位分析及其变化情况", height=80)
    submit_btn = st.button("生成答案", use_container_width=True)

# 左侧主内容区
with col1:
    st.markdown("<h3 style='margin-top: 24px;'>检索结果</h3>", unsafe_allow_html=True)
    
    if submit_btn and user_question.strip():
        with st.spinner("正在生成答案，请稍候..."):
            try:
                answer = pipeline.answer_single_question(user_question, kind="string", display_func=st.write)
                # 兼容 answer 可能为 str 或 dict
                if isinstance(answer, str):
                    try:
                        answer_dict = json.loads(answer)
                    except Exception:
                        st.error("返回内容无法解析为结构化答案：" + str(answer))
                        answer_dict = {}
                else:
                    answer_dict = answer
                # 优先从 content 字段取各项内容
                content = answer_dict.get("content", answer_dict)
                # content = content.get("final_answer", "")
                # 如果 content 是字符串，先解析为 dict
                if isinstance(content, str):
                    try:
                        content = json.loads(content)
                    except Exception:
                        st.error("content 字段不是合法的 JSON 字符串！")
                        content = {}
                # print('content=', content)
                # print('type(content)=', type(content))
                        
                step_by_step = content.get("step_by_step_analysis", "-")
                reasoning_summary = content.get("reasoning_summary", "-")
                relevant_pages = content.get("relevant_pages", [])
                final_answer = content.get("final_answer", "-")
                # 打印调试（已重定向到日志）
                logger.debug(f"step_by_step_analysis: {step_by_step}")
                logger.debug(f"reasoning_summary: {reasoning_summary}")
                logger.debug(f"relevant_pages: {relevant_pages}")
                logger.debug(f"final_answer: {final_answer}")
                st.markdown("**分步推理：**")
                st.info(step_by_step)
                st.markdown("**推理摘要：**")
                st.success(reasoning_summary)
                # st.markdown("**相关页面：** ")
                # st.write(relevant_pages)
                st.markdown("**最终答案：**")
                st.markdown(f"<div style='background:#f6f8fa;padding:16px;border-radius:8px;font-size:18px;'>{final_answer}</div>", unsafe_allow_html=True)
            except Exception as e:
                logger.error(f"生成答案时出错: {e}", exc_info=True)
                st.error(f"生成答案时出错: {e}")
    else:
        st.info("请在右侧输入问题并点击【生成答案】") 