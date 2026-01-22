import 'package:flutter/material.dart';

class MOUScreen extends StatefulWidget {
  final String startupName;
  final String investorName; // Optional, can be 'Investor' default
  final VoidCallback onAgree;

  const MOUScreen({
    super.key,
    required this.startupName,
    this.investorName = 'Investor',
    required this.onAgree,
  });

  @override
  State<MOUScreen> createState() => _MOUScreenState();
}

class _MOUScreenState extends State<MOUScreen> {
  int? _expandedIndex;
  bool _isAgreed = false;
  final ScrollController _scrollController = ScrollController();

  // Premium Legal Colors
  final Color _primaryColor = const Color(0xFF1A237E); // Deep Navy
  final Color _accentColor = const Color(0xFFC5CAE9); // Light Indigo
  final Color _paperColor = const Color(0xFFFAFAFA); // Off White
  final Color _textColor = const Color(0xFF212121); // Almost Black

  final List<Map<String, String>> _agreements = [
    {
      'title': 'Equity Investment',
      'icon': 'equity',
      'content': '''MEMORANDUM OF UNDERSTANDING (Equity Investment)
This Memorandum of Understanding (“MoU”) is made on this ___ day of ________, 20__.

BETWEEN
[Startup Name], a company incorporated under the Companies Act, 2013, having its registered office at [Address], hereinafter referred to as the “Startup”
AND
[Investor Name], residing at [Address], hereinafter referred to as the “Investor”.

The Startup and the Investor are collectively referred to as the “Parties”.

1. Purpose
The purpose of this MoU is to record the understanding between the Parties regarding an equity-based investment in the Startup.

2. Investment & Equity
The Investor agrees to invest a sum of ₹________ in consideration for ___% equity in the Startup, subject to applicable laws.

3. Management & Control
Day-to-day management shall remain with the Startup unless otherwise agreed in writing.

4. Confidentiality
Both Parties shall maintain confidentiality of all information exchanged under this MoU.

5. Term & Termination
This MoU shall remain valid until definitive agreements are executed or terminated by either Party with written notice.

6. Governing Law & Jurisdiction
This MoU shall be governed by the laws of India. Courts at [City] shall have jurisdiction.

7. Non-Binding Nature
This MoU is non-binding except for confidentiality and governing law clauses.

IN WITNESS WHEREOF, the Parties have executed this MoU on the date first written above.
'''
    },
    {
      'title': 'Convertible Investment',
      'icon': 'convertible',
      'content': '''MEMORANDUM OF UNDERSTANDING (Convertible Investment)
This Memorandum of Understanding (“MoU”) is made on this ___ day of ________, 20__.

BETWEEN
[Startup Name], having its registered office at [Address];
AND
[Investor Name], residing at [Address].

1. Purpose
This MoU records a convertible investment arrangement between the Parties.

2. Investment
The Investor agrees to invest ₹________ as a convertible instrument.

3. Conversion
The investment shall convert into equity upon a mutually agreed triggering event.

4. No Ownership Before Conversion
No equity or voting rights shall arise until conversion.

5. Confidentiality
All information exchanged shall remain confidential.

6. Governing Law
This MoU shall be governed by the laws of India.

7. Non-Binding Nature
This MoU is indicative and non-binding.

IN WITNESS WHEREOF, the Parties have executed this MoU on the date first written above.
'''
    },
    {
      'title': 'Revenue Sharing',
      'icon': 'revenue',
      'content': '''MEMORANDUM OF UNDERSTANDING (Revenue Sharing)
This Memorandum of Understanding (“MoU”) is made on this ___ day of ________, 20__.

BETWEEN
[Startup Name], having its registered office at [Address];
AND
[Investor Name], residing at [Address].

1. Purpose
To establish a revenue-sharing arrangement between the Parties.

2. Revenue Share
The Startup shall share % of its revenue with the Investor until ₹_____ is paid.

3. Payment Schedule
Payments shall be made on a monthly or quarterly basis.

4. No Equity
This MoU does not grant any ownership rights.

5. Confidentiality
All business information shall remain confidential.

6. Governing Law
This MoU shall be governed by the laws of India.

7. Non-Binding Nature
This MoU is non-binding in nature.

IN WITNESS WHEREOF, the Parties have executed this MoU on the date first written above.
'''
    },
    {
      'title': 'Technology Transfer / IP',
      'icon': 'tech',
      'content': '''MEMORANDUM OF UNDERSTANDING (Technology Transfer / IP)
This Memorandum of Understanding (“MoU”) is made on this ___ day of ________, 20__.

BETWEEN
[Startup Name], having its registered office at [Address];
AND
[Technology Provider Name], having its address at [Address].

1. Purpose
To outline the understanding for technology or intellectual property usage.

2. Technology Access
The Provider grants the Startup limited rights to use specified technology.

3. IP Ownership
All intellectual property shall remain with the Provider unless agreed otherwise.

4. Confidentiality
All technical and business information shall remain confidential.

5. Governing Law
This MoU shall be governed by the laws of India.

6. Non-Binding Nature
This MoU is indicative and non-binding.

IN WITNESS WHEREOF, the Parties have executed this MoU on the date first written above.
'''
    },
    {
      'title': 'Strategic Partnership',
      'icon': 'partner',
      'content': '''MEMORANDUM OF UNDERSTANDING (Strategic Partnership)
This Memorandum of Understanding (“MoU”) is made on this ___ day of ________, 20__.

BETWEEN
[Startup Name], having its registered office at [Address];
AND
[Partner Name], having its address at [Address].

1. Purpose
To establish a strategic collaboration between the Parties.

2. Scope of Collaboration
The Parties may collaborate through resource sharing, mentorship, or market access.

3. No Legal Partnership
This MoU does not create a partnership, joint venture, or agency.

4. Confidentiality
All shared information shall remain confidential.

5. Governing Law
This MoU shall be governed by the laws of India.

6. Non-Binding Nature
This MoU reflects mutual intent and is non-binding.

IN WITNESS WHEREOF, the Parties have executed this MoU on the date first written above.
'''
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1), // Light blue-grey frame
      appBar: AppBar(
        title: Text(
          'Select Agreement Type',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _agreements.length,
              itemBuilder: (context, index) {
                return _buildAgreementCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Icon(Icons.gavel, size: 48, color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            'Memorandum of Understanding',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the appropriate legal framework for your collaboration with ${widget.startupName}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCard(int index) {
    final agreement = _agreements[index];
    final bool isExpanded = _expandedIndex == index;
    
    IconData getIcon(String type) {
      switch(type) {
        case 'equity': return Icons.pie_chart;
        case 'convertible': return Icons.currency_exchange;
        case 'revenue': return Icons.percent;
        case 'tech': return Icons.memory;
        case 'partner': return Icons.handshake;
        default: return Icons.article;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isExpanded ? Border.all(color: _primaryColor, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  // Toggle expansion and reset agreement when closing or switching
                  if (isExpanded) {
                    _expandedIndex = null;
                    _isAgreed = false;
                  } else {
                    _expandedIndex = index;
                    _isAgreed = false;
                  }
                });
                if (!isExpanded) {
                  // Wait for expansion animation then scroll
                  Future.delayed(const Duration(milliseconds: 300), () {
                     _scrollController.animateTo(
                        _scrollController.offset + 100, // Small scroll nudge
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                     );
                  });
                }
              },
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: Radius.circular(isExpanded ? 0 : 12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isExpanded ? _primaryColor : _paperColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        getIcon(agreement['icon']!),
                        color: isExpanded ? Colors.white : _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agreement['title']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                              fontFamily: 'Serif', // Adds a legal touch
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Click title to collapse',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                         BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                         )
                      ]
                    ),
                    child: Text(
                      agreement['content']!
                          .replaceAll('[Startup Name]', widget.startupName)
                          .replaceAll('[Investor Name]', widget.investorName)
                          .replaceAll('[Technology Provider Name]', widget.startupName)
                          .replaceAll('[Partner Name]', widget.investorName),
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12, // Slightly smaller for dense text
                        height: 1.6,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Section Inside the Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey[100]!),
                    ),
                    child: Column(
                      children: [
                         Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _isAgreed,
                                activeColor: _primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAgreed = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAgreed = !_isAgreed;
                                  });
                                },
                                child: Text(
                                  'I have read and agree to these terms.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isAgreed
                                ? () {
                                    widget.onAgree();
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              disabledBackgroundColor: Colors.grey[300],
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Proceed to Payment',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
