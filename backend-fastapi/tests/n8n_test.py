import requests
import time
import itertools
import json

WEBHOOK_URL = "http://localhost:5678/webhook-test/new-ticket"

# 四种工单模板
tickets = [
    {
        "issue_title": "支付失败",
        "issue_description": "用户支付成功但订单未更新，导致重复付款风险。",
        "customer_name": "张三",
        "customer_email": "zhangsan@example.com",
        "urgency": "critical"
    },
    {
        "issue_title": "系统性能下降",
        "issue_description": "用户反馈网站响应速度明显变慢。",
        "customer_name": "李四",
        "customer_email": "lisi@example.com",
        "urgency": "high"
    },
    {
        "issue_title": "功能咨询",
        "issue_description": "客户询问如何使用导出功能。",
        "customer_name": "王五",
        "customer_email": "wangwu@example.com",
        "urgency": "normal"
    },
    {
        "issue_title": "意见反馈",
        "issue_description": "客户提出界面美观方面的建议。",
        "customer_name": "赵六",
        "customer_email": "zhaoliu@example.com",
        "urgency": "low"
    }
]

def send_ticket(ticket):
    """发送单个工单"""
    try:
        resp = requests.post(WEBHOOK_URL, json=ticket, timeout=10)
        
        print(f"\n{'='*60}")
        print(f"发送工单: {ticket['issue_title']}")
        print(f"紧急程度: {ticket['urgency']}")
        print(f"状态码: {resp.status_code}")
        
        try:
            response_data = resp.json()
            print(f"响应: {json.dumps(response_data, ensure_ascii=False, indent=2)}")
            
            if resp.status_code == 404:
                hint = response_data.get("hint", "")
                if "Execute workflow" in hint:
                    print("\n⚠️  提示: 需要在 n8n 画布上点击 'Execute workflow' 按钮")
        except:
            print(f"响应文本: {resp.text[:200]}")
        
        if resp.status_code == 200:
            print("✅ 工单发送成功！")
        else:
            print(f"❌ 工单发送失败 (状态码: {resp.status_code})")
        
        print(f"{'='*60}\n")
        
        return resp.status_code == 200
        
    except requests.exceptions.ConnectionError:
        print(f"\n❌ 错误: 无法连接到 n8n 服务")
        print("   请确保 n8n 正在运行\n")
        return False
    except requests.exceptions.Timeout:
        print(f"\n❌ 错误: 连接 n8n 超时\n")
        return False
    except Exception as e:
        print(f"\n❌ 错误: {str(e)}\n")
        return False

def batch_mode():
    """批量模式：依次发送四种工单，每次间隔10秒"""
    for ticket in tickets:
        send_ticket(ticket)
        time.sleep(10)

def single_mode():
    """单次模式：每次只发一种工单，但保证和上次不同"""
    # 无限循环，每次取不同工单
    for ticket in itertools.cycle(tickets):
        send_ticket(ticket)
        time.sleep(10)

if __name__ == "__main__":
    print("\n" + "="*60)
    print("n8n 工单测试工具")
    print(f"Webhook URL: {WEBHOOK_URL}")
    print("="*60)
    print("\n选择模式：")
    print("  1 = 批量模式（依次发送四种工单，每次间隔10秒）")
    print("  2 = 单次模式（循环发送，每次间隔10秒）")
    print("  3 = 测试单个工单")
    
    mode = input("\n请输入模式编号: ").strip()
    
    if mode == "1":
        batch_mode()
    elif mode == "2":
        single_mode()
    elif mode == "3":
        print("\n发送测试工单...")
        send_ticket(tickets[0])
    else:
        print("无效选择")
