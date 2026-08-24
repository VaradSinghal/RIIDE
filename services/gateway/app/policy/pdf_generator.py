import io
import datetime
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.units import inch

def generate_policy_pdf(policy_data: dict) -> io.BytesIO:
    """
    Generates an IRDAI-compliant PDF policy document.
    Returns a BytesIO stream containing the PDF.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, 
        pagesize=A4,
        rightMargin=40, leftMargin=40,
        topMargin=40, bottomMargin=40
    )
    
    Story = []
    styles = getSampleStyleSheet()
    
    # Custom Styles
    title_style = ParagraphStyle(
        'TitleStyle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor("#193A6F"),
        spaceAfter=20,
        alignment=1 # Center
    )
    h2_style = ParagraphStyle(
        'H2Style',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor("#193A6F"),
        spaceBefore=12,
        spaceAfter=6
    )
    normal_style = styles['Normal']
    normal_style.fontSize = 11
    normal_style.leading = 14
    
    # 1. Header
    Story.append(Paragraph("<b>GigKavach</b>", title_style))
    Story.append(Paragraph("IRDAI Micro-Insurance Parametric Policy", ParagraphStyle(
        'Subtitle', parent=styles['Normal'], alignment=1, fontSize=12, textColor=colors.gray
    )))
    Story.append(Spacer(1, 0.3 * inch))
    
    # Policy Metadata
    issued_date = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    metadata_data = [
        ["Policy Number:", policy_data.get("policy_id", "GK-POL-DEMO-1234")],
        ["Date of Issue:", issued_date],
        ["IRDAI UIN:", "GK-MIC-PAR-2026-01"]
    ]
    meta_t = Table(metadata_data, colWidths=[1.5*inch, 3*inch])
    meta_t.setStyle(TableStyle([
        ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.darkslategray),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    Story.append(meta_t)
    Story.append(Spacer(1, 0.2 * inch))
    
    # 2. Policyholder Details
    Story.append(Paragraph("Policyholder Information", h2_style))
    ph_data = [
        ["Name:", policy_data.get("name", "Unknown")],
        ["Aadhaar (Masked):", policy_data.get("aadhaar", "XXXX-XXXX-XXXX")],
        ["Verified Platform:", policy_data.get("verified_platform", "Not Linked").title()],
        ["Vehicle Type:", policy_data.get("vehicle_type", "bike").title()]
    ]
    ph_t = Table(ph_data, colWidths=[2*inch, 3*inch])
    ph_t.setStyle(TableStyle([
        ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    Story.append(ph_t)
    Story.append(Spacer(1, 0.2 * inch))
    
    # 3. Coverage Details
    Story.append(Paragraph("Coverage Summary", h2_style))
    cov_data = [
        ["Plan Tier", policy_data.get("plan_tier", "standard").upper()],
        ["Weekly Premium", f"Rs. {policy_data.get('weekly_premium', 0)}"],
        ["Coverage Ceiling", f"Rs. {policy_data.get('coverage_ceiling', 0)}"],
        ["Valid From", policy_data.get("valid_from", "N/A")],
        ["Valid Until", policy_data.get("valid_until", "N/A")],
        ["Working Zone (H3)", policy_data.get("h3_zone", "Unknown")]
    ]
    cov_t = Table(cov_data, colWidths=[2*inch, 3*inch])
    cov_t.setStyle(TableStyle([
        ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F0F4F8")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    Story.append(cov_t)
    Story.append(Spacer(1, 0.3 * inch))
    
    # 4. Terms & Conditions
    Story.append(Paragraph("Terms and Conditions", h2_style))
    terms = """
    <b>1. Triggers:</b> Payouts are triggered autonomously via Oracle APIs (IMD for weather, AQI for pollution). 
    No manual claim intimation is required.<br/>
    <b>2. Eligibility:</b> Policyholder must be in the designated H3 Zone during the active triggering event to be eligible.<br/>
    <b>3. Liability:</b> This is a parametric micro-insurance product. Liability is limited to the coverage ceiling.
    """
    Story.append(Paragraph(terms, normal_style))
    Story.append(Spacer(1, 0.5 * inch))
    
    # 5. Digital Signature Block
    Story.append(Paragraph("Digital Authorization", h2_style))
    sign_data = [
        ["Insurer E-Sign", "Policyholder E-Sign"],
        ["GigKavach Underwriting Auth", f"Digitally Signed by: {policy_data.get('name', 'Policyholder')}"],
        ["Status: Verified", "Status: Aadhaar OTP Verified / Accepted"]
    ]
    sign_t = Table(sign_data, colWidths=[3*inch, 3*inch])
    sign_t.setStyle(TableStyle([
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('TEXTCOLOR', (0,0), (-1,0), colors.darkslategray),
        ('FONTNAME', (0,1), (-1,1), 'Times-Italic'),
        ('TEXTCOLOR', (0,1), (-1,1), colors.blue),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('LINEABOVE', (0,1), (-1,1), 1, colors.black),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    Story.append(sign_t)
    
    # Build PDF
    doc.build(Story)
    buffer.seek(0)
    return buffer
