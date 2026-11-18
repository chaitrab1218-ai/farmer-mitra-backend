SMART FERTILIZER APP - UPDATED PROJECT

ಹೊಸ Features:
- Mobile-friendly Home screen ಮತ್ತು fertilizer search
- Nitrogen, Phosphatic, Potassic, Complex, Water Soluble, Micronutrients, Organic, Biofertilizer categories
- ಬೇರೆ ಅಂಗಡಿಗಳ ಬೆಲೆ ಹೋಲಿಕೆ
- Shop ಮತ್ತು stock ವಿವರಗಳು
- Demo cart (ಇನ್ನೂ ನಿಜವಾದ order/payment ಇಲ್ಲ)
- Google Sheets CSV link ಮೂಲಕ data refresh

Google Sheets ಸಂಪರ್ಕಿಸುವ ವಿಧಾನ:
1. Google Sheets ನಲ್ಲಿ ಹೊಸ spreadsheet ರಚಿಸಿ.
2. fertilizer_sheet_template.csv ಫೈಲ್‌ನ ಮೊದಲ ಸಾಲಿನ column ಹೆಸರುಗಳನ್ನು ಅದೇ ಕ್ರಮದಲ್ಲಿ Sheet ನಲ್ಲಿ ಹಾಕಿ.
3. ಪ್ರತಿ ಅಂಗಡಿ/ಉತ್ಪನ್ನಕ್ಕೆ ಒಂದೊಂದು row ಸೇರಿಸಿ.
4. Google Sheets ನಲ್ಲಿ File > Share > Publish to web ತೆರೆಯಿರಿ.
5. ಸರಿಯಾದ worksheet/tab ಆಯ್ಕೆ ಮಾಡಿ, format ನಲ್ಲಿ Comma-separated values (.csv) ಆಯ್ಕೆ ಮಾಡಿ Publish ಒತ್ತಿ.
6. ಸಿಗುವ published CSV link ಅನ್ನು copy ಮಾಡಿ.
7. App ಓಡಿಸಿ ಮೇಲಿನ sync icon ಒತ್ತಿ, ಆ CSV link paste ಮಾಡಿ Save & Sync ಒತ್ತಿ.

CSV columns ಕ್ರಮ ಬದಲಿಸಬೇಡಿ:
id,name,category,brand,weight,price,shopName,district,phone,stock,updatedAt

ಮುಖ್ಯ:
- App ಒಳಗಿನ ಆರಂಭಿಕ ಬೆಲೆಗಳು ಮತ್ತು ಅಂಗಡಿಗಳು SAMPLE/DEMO ಮಾತ್ರ; ನಿಜವಾದ ಮಾರುಕಟ್ಟೆ ಅಥವಾ ಸರ್ಕಾರಿ ದರಗಳೆಂದು ಪರಿಗಣಿಸಬೇಡಿ.
- Government ಅಧಿಕೃತ price feed/API ಇನ್ನೂ ಸಂಪರ್ಕಿಸಿಲ್ಲ. Sheet ನಲ್ಲಿ ಅಧಿಕೃತವಾಗಿ ಪರಿಶೀಲಿಸಿದ ದರಗಳನ್ನು ಸೇರಿಸಿದಾಗ ಮಾತ್ರ App ಅವನ್ನು ತೋರಿಸುತ್ತದೆ.
- Stock ಮತ್ತು ಅಂಗಡಿ ವಿವರಗಳನ್ನು ಅಂಗಡಿ ಮಾಲೀಕರು/ನಿರ್ವಹಕರು update ಮಾಡಬೇಕು.
- Cart ಈಗ demo ಮಾತ್ರ; payment, order placement, delivery tracking ಮತ್ತು shop verification ಇನ್ನೂ ಅಭಿವೃದ್ಧಿಪಡಿಸಬೇಕಿದೆ.
- Google Sheet ಅನ್ನು Publish to web ಮಾಡಿದರೆ ಅದರ data ಸಾರ್ವಜನಿಕವಾಗಿ ಓದಲು ಸಾಧ್ಯ. ಸಾರ್ವಜನಿಕಗೊಳಿಸಲು ಅನುಮತಿ ಇರುವ ದರ/ಸ್ಟಾಕ್ ಮಾಹಿತಿಯನ್ನಷ್ಟೇ ಇಡಿ. ಖಾಸಗಿ ಮಾಹಿತಿ, ಬ್ಯಾಂಕ್ ಅಥವಾ ಗ್ರಾಹಕರ ವಿವರಗಳನ್ನು ಹಾಕಬೇಡಿ.

VS Code ನಲ್ಲಿ:
1. ಹಳೆಯ project ಅನ್ನು backup ಮಾಡಿ.
2. ಈ ZIP ಅನ್ನು ಹೊಸ folder ಗೆ extract ಮಾಡಿ ಅಥವಾ ಅದರ smart_fertilizer_app folder ಒಳಗಿನ ಫೈಲ್‌ಗಳನ್ನು ನಿಮ್ಮ project ಗೆ copy/replace ಮಾಡಿ.
3. Terminal ನಲ್ಲಿ project root ಗೆ ಹೋಗಿ:
   flutter pub get
   flutter run -d chrome
4. Android emulator ಅಥವಾ USB-debugging enabled phone ಆಯ್ಕೆಮಾಡಿ:
   flutter devices
   flutter run -d <device-id>

ಮೊದಲ ಬಾರಿ dependencies download ಆಗಲು internet ಬೇಕು.
