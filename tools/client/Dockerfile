# Navigateur headless du client. Version d'image et de Playwright épinglées ensemble.
FROM mcr.microsoft.com/playwright/python:v1.49.1-noble
RUN pip install --no-cache-dir --break-system-packages playwright==1.49.1
COPY driver.py ctl.py /driver/
CMD ["python3", "/driver/driver.py"]
