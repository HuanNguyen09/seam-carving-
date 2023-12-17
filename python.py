import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent

def get_amazon_product_title(product_id):
    url = f"https://www.amazon.com/dp/{product_id}"
    
    # Sử dụng User-Agent giả để giả mạo trình duyệt
    headers = {"User-Agent": UserAgent().random}

    # Gửi yêu cầu để tải trang web với User-Agent giả
    response = requests.get(url, headers=headers)
    print(response.text)
    # if response.status_code == 200:
    #     # Sử dụng BeautifulSoup để phân tích cú pháp HTML
    #     soup = BeautifulSoup(response.text, "html.parser")
    #     title_section_div = soup.find('div', {'id': 'titleSection', 'class':'a-section a-spacing-none'})
    #     # Kiểm tra xem thẻ có tồn tại hay không
    #     if title_section_div:
    #         # Trong thẻ div, tìm thẻ h1 có id="title"
    #         title_tag = title_section_div.find('h1', {'id': 'title'})

    #         # Kiểm tra xem thẻ có tồn tại hay không
    #         if title_tag:
    #             # Trong thẻ h1, tìm thẻ span có id="productTitle" và class="a-size-large"
    #             product_title_tag = title_tag.find('span', {'id': 'productTitle'})

    #             # Lấy nội dung của thẻ span
    #             product_title = product_title_tag.get_text(strip=True) if product_title_tag else None

    #             return product_title
    #         else:
    #             print("Không tìm thấy thẻ h1 với id='title'.")
    #     else:
    #         print("Không tìm thấy thẻ div với id='titleSection'.")
    # else:
    #     print(f"Lỗi {response.status_code}: Không thể tải trang web.")

    return None

# Thay "YOUR_PRODUCT_ID" bằng mã sản phẩm thực tế của bạn
product_id = "B006K2ZZ7K"
product_title = get_amazon_product_title(product_id)

if product_title:
    print(f"Tên sản phẩm của {product_id} là: {product_title}")
else:
    print(f"Không thể lấy được tên sản phẩm cho {product_id}")

    # <div id="titleSection" class="a-section a-spacing-none"> <h1 id="title" class="a-size-large a-spacing-none"> <span id="productTitle" class="a-size-large product-title-word-break">        Salt Water Taffy - Assorted, 5 lbs       </span>       </h1> <div id="expandTitleToggle" class="a-section a-spacing-none expand aok-hidden"></div>  </div>
