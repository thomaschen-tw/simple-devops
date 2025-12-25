/**
 * 反馈页面组件
 * 提供表单用于提交用户反馈和问题报告
 */
import { useState } from "react";
import { submitFeedback } from "../api";

function FeedbackPage() {
  const [issueTitle, setIssueTitle] = useState("");
  const [issueDescription, setIssueDescription] = useState("");
  const [customerName, setCustomerName] = useState("");
  const [customerEmail, setCustomerEmail] = useState("");
  const [urgency, setUrgency] = useState("normal");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  /**
   * 处理表单提交
   * 调用后端反馈接口，提交反馈到 n8n 进行自动化处理
   * 
   * @param {Event} event - 表单提交事件
   */
  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoading(true);
    setMessage("");
    setError("");
    
    try {
      const result = await submitFeedback({
        issue_title: issueTitle.trim(),
        issue_description: issueDescription.trim(),
        customer_name: customerName.trim(),
        customer_email: customerEmail.trim().toLowerCase(),
        urgency: urgency,
      });
      
      setMessage(result.message || "反馈已成功提交，我们会尽快处理");
      // 清空表单
      setIssueTitle("");
      setIssueDescription("");
      setCustomerName("");
      setCustomerEmail("");
      setUrgency("normal");
    } catch (err) {
      setError(err.message || "提交失败，请稍后重试");
    } finally {
      setLoading(false);
    }
  };

  /**
   * 根据紧急程度获取提示信息
   */
  const getUrgencyHint = (urgency) => {
    const hints = {
      critical: "⚠️ 紧急：系统故障或数据丢失风险，会立即处理并通知相关人员",
      high: "🔴 高优先级：影响正常使用的问题，会优先处理",
      normal: "🟡 普通：功能使用问题，会在工作时间内尽快处理",
      low: "🟢 低优先级：一般咨询或建议，系统会自动发送确认邮件"
    };
    return hints[urgency] || "";
  };

  return (
    <section className="card">
      <h2>问题反馈</h2>
      <p style={{ color: "#64748b", marginBottom: "20px" }}>
        如果您在使用过程中遇到任何问题，请填写以下表单。我们会通过自动化系统尽快处理您的反馈。
      </p>
      
      <form onSubmit={handleSubmit} className="form">
        <label>
          问题标题 <span style={{ color: "#b91c1c" }}>*</span>
          <input
            type="text"
            value={issueTitle}
            onChange={(e) => setIssueTitle(e.target.value)}
            placeholder="例如：支付失败、页面无法加载等"
            required
          />
        </label>
        
        <label>
          问题描述 <span style={{ color: "#b91c1c" }}>*</span>
          <textarea
            rows="6"
            value={issueDescription}
            onChange={(e) => setIssueDescription(e.target.value)}
            placeholder="请详细描述您遇到的问题，包括操作步骤、错误信息等"
            required
          />
        </label>
        
        <label>
          您的姓名 <span style={{ color: "#b91c1c" }}>*</span>
          <input
            type="text"
            value={customerName}
            onChange={(e) => setCustomerName(e.target.value)}
            placeholder="请输入您的姓名"
            required
          />
        </label>
        
        <label>
          您的邮箱 <span style={{ color: "#b91c1c" }}>*</span>
          <input
            type="email"
            value={customerEmail}
            onChange={(e) => setCustomerEmail(e.target.value)}
            placeholder="example@email.com"
            required
          />
        </label>
        
        <label>
          紧急程度 <span style={{ color: "#b91c1c" }}>*</span>
          <select
            value={urgency}
            onChange={(e) => setUrgency(e.target.value)}
            style={{
              width: "100%",
              padding: "10px",
              border: "1px solid #cbd5e1",
              borderRadius: "6px",
              font: "inherit",
            }}
            required
          >
            <option value="low">低 - 一般咨询或建议</option>
            <option value="normal">普通 - 功能使用问题</option>
            <option value="high">高 - 影响正常使用的问题</option>
            <option value="critical">紧急 - 系统故障或数据丢失风险</option>
          </select>
          {urgency && (
            <small style={{ 
              display: "block", 
              marginTop: "4px", 
              color: "#64748b",
              fontSize: "0.9em"
            }}>
              {getUrgencyHint(urgency)}
            </small>
          )}
        </label>
        
        <button type="submit" disabled={loading}>
          {loading ? "提交中..." : "提交反馈"}
        </button>
      </form>
      
      {message && <p className="success">{message}</p>}
      {error && <p className="error">{error}</p>}
    </section>
  );
}

export default FeedbackPage;

