var dependencyDict, levelHeight, maximum, parseConll, tagDict, under, wordHeight, wordWidth;

wordWidth = 60;

wordHeight = 20;

levelHeight = function(level) {
  return 2 + Math.pow(level, 1.8) * 10;
};

window.drawTree = function(svgElement, conllData) {
  var arrows, data, dependencies, e, edge, edges, i, item, j, k, len, len1, len2, svg, tags, treeHeight, treeWidth, triangle, words;
  svg = d3.select(svgElement);
  data = parseConll(conllData);
  // compute edge levels
  edges = (function() {
    var i, len, results;
    results = [];
    for (i = 0, len = data.length; i < len; i++) {
      item = data[i];
      if (item.id) {
        results.push(item);
      }
    }
    return results;
  })();
  for (i = 0, len = edges.length; i < len; i++) {
    edge = edges[i];
    for (j = 0, len1 = edges.length; j < len1; j++) {
      edge = edges[j];
      edge.level = 1 + maximum((function() {
        var k, len2, results;
        results = [];
        for (k = 0, len2 = edges.length; k < len2; k++) {
          e = edges[k];
          if (under(edge, e)) {
            results.push(e.level);
          }
        }
        return results;
      })());
    }
  }
  // compute height
  treeWidth = wordWidth * data.length - wordWidth / 3;
  treeHeight = levelHeight(maximum((function() {
    var k, len2, results;
    results = [];
    for (k = 0, len2 = data.length; k < len2; k++) {
      edge = data[k];
      results.push(edge.level);
    }
    return results;
  })())) + 2 * wordHeight;
  for (k = 0, len2 = data.length; k < len2; k++) {
    item = data[k];
    item.bottom = treeHeight - 1.8 * wordHeight;
    item.top = item.bottom - levelHeight(item.level);
    item.left = treeWidth - item.id * wordWidth;
    item.right = treeWidth - item.head * wordWidth;
    item.mid = (item.right + item.left) / 2;
    item.diff = (item.right - item.left) / 4;
    item.arrow = item.top + (item.bottom - item.top) * .25;
  }
  // draw svg
  svg.selectAll('text, path').remove();
  svg.attr('xmlns', 'http://www.w3.org/2000/svg');
  svg.attr('width', treeWidth + 2 * wordWidth / 3).attr('height', treeHeight + wordHeight / 2);
  words = svg.selectAll('.form').data(data).enter().append('text').text(function(d) {
    return d.form;
  }).attr('class', function(d) {
    return `form w${d.id}`;
  }).attr('x', function(d) {
    return treeWidth - wordWidth * d.id;
  }).attr('y', treeHeight - wordHeight).on('mouseover', function(d) {
    svg.selectAll('.form, .deprel, .edge, .arrow').classed('active', false);
    svg.selectAll('.tag').attr('opacity', 0);
    svg.selectAll(`.w${d.id}`).classed('active', true);
    return svg.select(`.tag.w${d.id}`).attr('opacity', 1);
  }).on('mouseout', function(d) {
    svg.selectAll('.form, .deprel, .edge, .arrow').classed('active', false);
    return svg.selectAll('.tag').attr('opacity', 0);
  }).attr('text-anchor', 'middle');
  tags = svg.selectAll('.tag').data(data).enter().append('text').text(function(d) {
    return d.tag;
  }).attr('class', function(d) {
    return `tag w${d.id}`;
  }).attr('x', function(d) {
    return treeWidth - wordWidth * d.id;
  }).attr('y', treeHeight).attr('opacity', 0).attr('text-anchor', 'middle').attr('font-size', '90%');
  edges = svg.selectAll('.edge').data(data).enter().append('path').filter(function(d) {
    return d.id;
  }).attr('class', function(d) {
    return `edge w${d.id} w${d.head}`;
  }).attr('d', function(d) {
    return `M${d.left},${d.bottom} C${d.mid - d.diff},${d.top} ${d.mid + d.diff},${d.top} ${d.right},${d.bottom}`;
  }).attr('fill', 'none').attr('stroke', 'black').attr('stroke-width', '1.5');
  dependencies = svg.selectAll('.deprel').data(data).enter().append('text').filter(function(d) {
    return d.id;
  }).text(function(d) {
    return d.deprel;
  }).attr('class', function(d) {
    return `deprel w${d.id} w${d.head}`;
  }).attr('x', function(d) {
    return d.mid;
  }).attr('y', function(d) {
    return d.arrow - 7;
  }).attr('text-anchor', 'middle').attr('font-size', '90%').append('title').text(function(d) {
    return dependencyDict[d.deprel];
  });
  triangle = d3.svg.symbol().type('triangle-up').size(5);
  return arrows = svg.selectAll('.arrow').data(data).enter().append('path').filter(function(d) {
    return d.id;
  }).attr('class', function(d) {
    return `arrow w${d.id} w${d.head}`;
  }).attr('d', triangle).attr('transform', function(d) {
    return `translate(${d.mid}, ${d.arrow}) rotate(${d.id < d.head ? '' : '-'}90)`;
  }).attr('fill', 'none').attr('stroke', 'black').attr('stroke-width', '1.5');
};

// functions
maximum = function(array) {
  return Math.max(0, Math.max.apply(null, array));
};

under = function(edge1, edge2) {
  var ma, mi;
  [mi, ma] = edge1.id < edge1.head ? [edge1.id, edge1.head] : [edge1.head, edge1.id];
  return edge1.id !== edge2.id && edge2.id >= mi && edge2.head >= mi && edge2.id <= ma && edge2.head <= ma;
};

parseConll = function(conllData) {
  var _, cpos, data, deprel, form, fpos, head, i, id, len, line, ref, tag, upos, xpos;
  data = [];
  data.push({
    id: 0,
    form: 'ریشه',
    tag: tagDict['root'],
    level: 0
  });
  ref = conllData.split('\n').slice(2);
  for (i = 0, len = ref.length; i < len; i++) {
    line = ref[i];
    if (!(line)) {
      continue;
    }
    [id, form, _, upos, xpos, _, head, deprel] = line.split('\t');
    if (xpos.includes('_')) {
      [cpos, fpos] = xpos.split('_');
      tag = tagDict[cpos] + ' ' + tagDict[fpos];
    } else {
      tag = tagDict[xpos];
    }
    data.push({
      id: Number(id),
      form: form,
      tag: tag,
      head: Number(head),
      deprel: deprel,
      level: 1
    });
  }
  return data;
};

tagDict = {
  'ADJ': 'صفت',
  'ADP': 'حرف اضافه',
  'ADV': 'قید',
  'AUX': 'فعل کمکی',
  'CCONJ': 'حرف ربط همپایه‌ساز',
  'DET': 'حرف تعریف',
  'INTJ': 'حرف ندا',
  'NOUN': 'اسم',
  'NUM': 'شمار',
  'PART': 'جزء دستوری',
  'PRON': 'ضمیر',
  'PROPN': 'اسم خاص',
  'PUNCT': 'علامت نگارشی',
  'SCONJ': 'حرف ربط وابسته‌ساز',
  'SYM': 'نماد',
  'VERB': 'فعل',
  'X': 'سایر',
  '': '',
  '1': 'اول',
  '2': 'دوم',
  '3': 'سوم',
  'ACT': 'معلوم',
  'ADR': 'نقش نمای ندا',
  'AJCM': 'تفضیلی',
  'AJP': 'مطلق',
  'AJSUP': 'عالی',
  'AMBAJ': 'صفت مبهم',
  'ANM': 'جاندار',
  'AVCM': 'تفضیلی',
  'AVP': 'مطلق',
  'AY': 'آینده اخباری',
  'CL': 'سببی',
  'COM': 'تفضیلی',
  'CONJ': 'نقش نمای همپایگی',
  'CREFX': 'بازتابی مشترک',
  'DEMAJ': 'صفت اشاره',
  'DEMON': 'اشاره',
  'EXAJ': 'صفت تعجبی',
  'GB': 'گذشته بعید اخباری',
  'GBEL': 'گذشته بعید التزامی',
  'GBES': 'گذشته بعید استمراری اخباری',
  'GBESE': 'گذشته بعید استمراری التزامی',
  'GEL': 'گذشته التزامی',
  'GES': 'گذشته استمراری اخباری',
  'GESEL': 'گذشته استمراری التزامی',
  'GN': 'گذشته نقلی اخباری',
  'GNES': 'گذشته نقلی استمراری اخباری',
  'GS': 'گذشته ساده اخباری',
  'H': 'حال اخباری',
  'HA': 'حال امری',
  'HEL': 'حال التزامی',
  'IANM': 'بی جان',
  'IDEN': 'شاخص',
  'INTG': 'پرسشی',
  'ISO': 'واژه تنها',
  'JOPER': 'شخصی پیوسته',
  'MODE': 'وجه',
  'MODL': 'وجهی',
  'N': 'اسم',
  'NXT': 'چسبیدگی از چپ',
  'PASS': 'مجهول',
  'PERS': 'شخص',
  'PLUR': 'جمع',
  'POSADR': 'پسین',
  'POSNUM': 'صفت شمارشی پسین',
  'POST': 'مطلق',
  'POSTP': 'حرف اضافه پسین',
  'PR': 'ضمیر',
  'PRADR': 'پیشین',
  'PREM': 'پیش توصیفگر',
  'PRENUM': 'صفت شمارشی پیشین',
  'PREP': 'حرف اضافه پیشین',
  'PRV': 'چسبیدگی از راست',
  'PSUS': 'شبه جمله',
  'PUNC': 'علامت نگارشی',
  'QUAJ': 'صفت پرسشی',
  'RECPR': 'متقابل',
  'SADV': 'مختص',
  'SEPER': 'شخصی جدا',
  'SING': 'مفرد',
  'SUBR': 'نقش نمای وابستگی',
  'SUP': 'عالی',
  'UCREFX': 'بازتابی غیرمشترک',
  'V': 'فعل',
  'root': ''
};

dependencyDict = {
  'acl': 'adnominal clause',
  'acl:relcl': 'relative clause modifier',
  'advcl': 'adverbial clause modifier',
  'advmod': 'adverbial modifier',
  'advmod:emph': 'emphasizing form, intensifier',
  'advmod:lmod': 'locative adverbial modifier',
  'amod': 'adjectival modifier',
  'appos': 'appositional modifier',
  'aux': 'auxiliary',
  'aux:pass': 'passive auxiliary',
  'case': 'case marking',
  'cc': 'coordinating conjunction',
  'cc:preconj': 'preconjunct',
  'ccomp': 'clausal complement',
  'clf': 'classifier',
  'compound': 'compound',
  'compound:lvc': 'light verb construction',
  'compound:prt': 'phrasal verb particle',
  'compound:redup': 'reduplicated compounds',
  'compound:svc': 'serial verb compounds',
  'conj': 'conjunct',
  'cop': 'copula',
  'csubj': 'clausal subject',
  'csubj:outer': 'outer clause clausal subject',
  'csubj:pass': 'clausal passive subject',
  'dep': 'unspecified deprel',
  'det': 'determiner',
  'det:numgov': 'pronominal quantifier governing the case of the noun',
  'det:nummod': 'pronominal quantifier agreeing in case with the noun',
  'det:poss': 'possessive determiner',
  'discourse': 'discourse element',
  'dislocated': 'dislocated elements',
  'expl': 'expletive',
  'expl:impers': 'impersonal expletive',
  'expl:pass': 'reflexive pronoun used in reflexive passive',
  'expl:pv': 'reflexive clitic with an inherently reflexive verb',
  'fixed': 'fixed multiword expression',
  'flat': 'flat multiword expression',
  'flat:foreign': 'foreign words',
  'flat:name': 'names',
  'goeswith': 'goes with',
  'iobj': 'indirect object',
  'list': 'list',
  'mark': 'marker',
  'nmod': 'nominal modifier',
  'nmod:poss': 'possessive nominal modifier',
  'nmod:tmod': 'temporal modifier',
  'nsubj': 'nominal subject',
  'nsubj:outer': 'outer clause nominal subject',
  'nsubj:pass': 'passive nominal subject',
  'nummod': 'numeric modifier',
  'nummod:gov': 'numeric modifier governing the case of the noun',
  'obj': 'object',
  'obl': 'oblique nominal',
  'obl:agent': 'agent modifier',
  'obl:arg': 'oblique argument',
  'obl:lmod': 'locative modifier',
  'obl:tmod': 'temporal modifier',
  'orphan': 'orphan',
  'parataxis': 'parataxis',
  'punct': 'punctuation',
  'reparandum': 'overridden disfluency',
  'root': 'root',
  'vocative': 'vocative',
  'xcomp': 'open clausal complement'
};
