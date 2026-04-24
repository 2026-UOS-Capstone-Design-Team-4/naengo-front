/// Vision API 가 반환하는 영어 레이블을 한국어 재료명으로 변환.
///
/// 설계 포인트:
///   1. **완전 일치** 먼저 시도  (예: 'Lemon' → '레몬')
///   2. 실패하면 **부분 일치** (긴 키부터 검사)
///      (예: 'POD Lemon Juice' → '레몬즙', 'Heinz Tomato Ketchup' → '케첩')
///   3. 사전에 없는 레이블은 `null` 반환 → 호출 측에서 자동 필터링.
///      덕분에 'Rectangle', 'Packaging', 'Logo' 같은 비(非) 식재료는 결과에서 제외됨.
///
/// 부분 일치는 **단어 경계** 를 고려해서 "pineapple" 이 "apple" 로 오매칭되는 걸 방지.
class IngredientTranslator {
  IngredientTranslator._();

  /// 영어(소문자) → 한국어 재료 사전.
  ///
  /// ⚠️ 추가 규칙
  ///   - 더 구체적인 표현도 긴 키로 등록 (예: 'lemon juice' 가 'lemon' 보다 우선 매칭)
  ///   - 브랜드/수식어가 붙는 경우는 중심 명사만 등록 (예: 'ketchup' 한 개로 'Heinz Tomato Ketchup' 도 커버)
  static const Map<String, String> _dict = {
    // ── 채소 (잎/뿌리/열매) ──
    'napa cabbage': '배추',
    'bok choy': '청경채',
    'green onion': '대파',
    'spring onion': '대파',
    'sweet potato': '고구마',
    'cherry tomato': '방울토마토',
    'bell pepper': '피망',
    'chili pepper': '고추',
    'red pepper': '홍고추',
    'green pepper': '풋고추',
    'bean sprouts': '콩나물',
    'baby spinach': '시금치',
    'iceberg lettuce': '양상추',
    'romaine lettuce': '로메인',
    'cabbage': '양배추',
    'lettuce': '상추',
    'kale': '케일',
    'spinach': '시금치',
    'arugula': '루꼴라',
    'carrot': '당근',
    'onion': '양파',
    'scallion': '쪽파',
    'garlic': '마늘',
    'ginger': '생강',
    'potato': '감자',
    'tomato': '토마토',
    'cucumber': '오이',
    'zucchini': '애호박',
    'pumpkin': '단호박',
    'squash': '호박',
    'eggplant': '가지',
    'mushroom': '버섯',
    'shiitake': '표고버섯',
    'enoki': '팽이버섯',
    'king oyster mushroom': '새송이버섯',
    'broccoli': '브로콜리',
    'cauliflower': '콜리플라워',
    'corn': '옥수수',
    'pea': '완두콩',
    'soybean': '콩',
    'bean': '콩',
    'radish': '무',
    'daikon': '무',
    'leek': '부추',
    'celery': '셀러리',
    'asparagus': '아스파라거스',
    'chive': '실파',
    'parsley': '파슬리',
    'cilantro': '고수',
    'basil': '바질',
    'mint': '민트',

    // ── 과일 / 주스 ──
    'lemon juice': '레몬즙',
    'lime juice': '라임즙',
    'orange juice': '오렌지주스',
    'apple juice': '사과주스',
    'tomato juice': '토마토주스',
    'apple': '사과',
    'banana': '바나나',
    'orange': '오렌지',
    'mandarin': '귤',
    'tangerine': '귤',
    'grape': '포도',
    'strawberry': '딸기',
    'blueberry': '블루베리',
    'raspberry': '라즈베리',
    'watermelon': '수박',
    'melon': '멜론',
    'peach': '복숭아',
    'pear': '배',
    'lemon': '레몬',
    'lime': '라임',
    'kiwi': '키위',
    'mango': '망고',
    'pineapple': '파인애플',
    'avocado': '아보카도',
    'persimmon': '감',
    'plum': '자두',

    // ── 육류 ──
    'chicken breast': '닭가슴살',
    'chicken thigh': '닭다리살',
    'chicken wing': '닭날개',
    'ground beef': '다진 소고기',
    'ground pork': '다진 돼지고기',
    'pork belly': '삼겹살',
    'pork shoulder': '목살',
    'pork rib': '돼지갈비',
    'beef rib': '소갈비',
    'beef steak': '스테이크',
    'steak': '스테이크',
    'beef': '소고기',
    'pork': '돼지고기',
    'chicken': '닭고기',
    'duck': '오리고기',
    'lamb': '양고기',
    'bacon': '베이컨',
    'ham': '햄',
    'sausage': '소시지',
    'pepperoni': '페퍼로니',
    'spam': '스팸',
    'meatball': '미트볼',

    // ── 해산물 ──
    'salmon': '연어',
    'tuna': '참치',
    'mackerel': '고등어',
    'shrimp': '새우',
    'prawn': '새우',
    'squid': '오징어',
    'octopus': '문어',
    'crab': '게',
    'lobster': '랍스터',
    'oyster': '굴',
    'clam': '조개',
    'mussel': '홍합',
    'scallop': '관자',
    'anchovy': '멸치',

    // ── 유제품 / 계란 ──
    'egg white': '계란 흰자',
    'egg yolk': '계란 노른자',
    'egg': '계란',
    'milk': '우유',
    'cream cheese': '크림치즈',
    'whipping cream': '휘핑크림',
    'sour cream': '사워크림',
    'cream': '생크림',
    'cheese': '치즈',
    'mozzarella': '모차렐라',
    'cheddar': '체다치즈',
    'parmesan': '파마산',
    'butter': '버터',
    'yogurt': '요거트',

    // ── 곡물 / 빵 / 면 ──
    'bread': '빵',
    'baguette': '바게트',
    'toast': '식빵',
    'tortilla': '토르티야',
    'brown rice': '현미',
    'cooked rice': '밥',
    'rice': '쌀',
    'ramen': '라면',
    'udon': '우동',
    'soba': '메밀면',
    'noodle': '면',
    'spaghetti': '스파게티',
    'macaroni': '마카로니',
    'pasta': '파스타',
    'flour': '밀가루',
    'oat': '귀리',
    'cereal': '시리얼',

    // ── 소스 / 조미료 ──
    'soy sauce': '간장',
    'fish sauce': '액젓',
    'oyster sauce': '굴소스',
    'hot sauce': '핫소스',
    'sriracha': '스리라차',
    'ketchup': '케첩',
    'mayonnaise': '마요네즈',
    'mustard': '머스타드',
    'gochujang': '고추장',
    'doenjang': '된장',
    'ssamjang': '쌈장',
    'chili paste': '고추장',
    'miso': '미소',
    'vinegar': '식초',
    'sesame oil': '참기름',
    'olive oil': '올리브유',
    'cooking oil': '식용유',
    'vegetable oil': '식용유',
    'brown sugar': '흑설탕',
    'salt': '소금',
    'sugar': '설탕',
    'black pepper': '후추',
    'white pepper': '백후추',
    'sesame seed': '참깨',
    'red pepper powder': '고춧가루',
    'curry powder': '카레가루',
    'honey': '꿀',
    'syrup': '시럽',

    // ── 가공식품 / 기타 ──
    'tofu': '두부',
    'kimchi': '김치',
    'seaweed': '김',
    'nori': '김',
    'laver': '김',
    'kelp': '다시마',
    'fish cake': '어묵',
    'dumpling': '만두',
    'mandu': '만두',
    'chocolate': '초콜릿',
    'nut': '견과류',
    'almond': '아몬드',
    'walnut': '호두',
    'peanut': '땅콩',
    'cashew': '캐슈넛',
  };

  /// 너무 일반적이라 재료로 안 쓸 레이블.
  /// Vision API 가 자주 반환하지만 요리 관점에선 무의미한 것들.
  static const Set<String> _tooGeneric = {
    // 음식 범주
    'food', 'foods',
    'ingredient', 'ingredients',
    'produce',
    'natural foods', 'whole food', 'whole foods',
    'dish', 'cuisine', 'recipe', 'meal',
    'plant', 'staple food', 'superfood',
    'snack', 'dessert',
    'finger food', 'comfort food', 'fast food', 'junk food',
    'packaged goods',
    'vegetable', 'vegetables', 'leaf vegetable',
    'fruit', 'fruits',
    'meat',
    // 비(非) 식재료 — 포장/배경 등
    'drink', 'beverage', 'liquid',
    'bottle', 'jar', 'can', 'container',
    'packaging', 'package', 'label', 'logo',
    'font', 'rectangle', 'circle', 'square',
    'plastic', 'glass', 'paper',
  };

  /// 영어 레이블을 한국어 재료명으로 변환.
  /// 사전에 등록된 재료가 아니면 **`null`** 반환 → 호출 측에서 필터링하면 됨.
  ///
  /// 예시:
  ///   translate('Lemon')                 // '레몬'
  ///   translate('POD Lemon Juice')       // '레몬즙'      (부분 일치)
  ///   translate('Heinz Tomato Ketchup')  // '케첩'        (부분 일치)
  ///   translate('Organic Baby Spinach')  // '시금치'      (부분 일치)
  ///   translate('Rectangle')             // null         (재료 아님)
  ///   translate('Food')                  // null         (너무 일반적)
  static String? translate(String english) {
    final lower = english.toLowerCase().trim();
    if (lower.isEmpty) return null;
    if (_tooGeneric.contains(lower)) return null;

    // 1차: 완전 일치
    final exact = _dict[lower];
    if (exact != null) return exact;

    // 2차: 부분 일치 — 긴 키부터 검사해서 더 구체적인 매칭 우선
    //      (예: 'lemon juice' 를 'lemon' 보다 먼저 시도)
    final keys = _dict.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in keys) {
      if (_containsAsWord(lower, key)) {
        return _dict[key];
      }
    }

    return null; // 사전에 없는 레이블 → 재료로 인정 안 함
  }

  /// `haystack` 안에서 `needle` 이 완전한 단어(어구)로 포함되는지 확인.
  ///
  /// 예:
  ///   _containsAsWord('pineapple', 'apple')            // false  (pine+apple)
  ///   _containsAsWord('pod lemon juice', 'lemon juice') // true
  ///   _containsAsWord('fresh lemon', 'lemon')          // true
  static bool _containsAsWord(String haystack, String needle) {
    var start = 0;
    while (true) {
      final idx = haystack.indexOf(needle, start);
      if (idx < 0) return false;
      final before = idx == 0 ? null : haystack.codeUnitAt(idx - 1);
      final afterPos = idx + needle.length;
      final after = afterPos >= haystack.length
          ? null
          : haystack.codeUnitAt(afterPos);
      if (!_isAlpha(before) && !_isAlpha(after)) return true;
      start = idx + 1;
    }
  }

  /// `code` 가 영문 알파벳(a-z)인지? (null = 문자열 경계 → 알파벳 아님)
  static bool _isAlpha(int? code) {
    if (code == null) return false;
    return code >= 0x61 && code <= 0x7A;
  }

  /// (기존 호환) 너무 일반적인 레이블인지 확인.
  /// 새 코드에선 `translate()` 가 `null` 을 반환하므로 보통 호출할 필요 없음.
  static bool isGeneric(String english) {
    return _tooGeneric.contains(english.toLowerCase().trim());
  }
}
