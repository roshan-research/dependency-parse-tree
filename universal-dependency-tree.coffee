
wordWidth = 60
wordHeight = 20
levelHeight = (level) -> 2 + Math.pow(level, 1.8) * 10

window.drawTree = (svgElement, conllData) ->
	svg = d3.select(svgElement)
	data = parseConll(conllData)

	# compute edge levels
	edges = (item for item in data when item.id)
	for edge in edges
		for edge in edges
			edge.level = 1 + maximum(e.level for e in edges when under(edge, e))

	# compute height
	treeWidth = wordWidth*data.length - wordWidth/3
	treeHeight = levelHeight(maximum(edge.level for edge in data)) + 2 * wordHeight
	for item in data
		item.bottom = treeHeight - 1.8 * wordHeight
		item.top = item.bottom - levelHeight(item.level)
		item.left = treeWidth - item.id * wordWidth
		item.right = treeWidth - item.head * wordWidth
		item.mid = (item.right+item.left)/2
		item.diff = (item.right-item.left)/4
		item.arrow = item.top + (item.bottom-item.top)*.25

	# draw svg
	svg.selectAll('text, path').remove()
	svg.attr('xmlns', 'http://www.w3.org/2000/svg')
	svg.attr('width', treeWidth + 2*wordWidth/3).attr('height', treeHeight + wordHeight/2)

	words = svg.selectAll('.form').data(data).enter()
		.append('text')
		.text((d) -> d.form)
		.attr('class', (d) -> "form w#{d.id}")
		.attr('x', (d) -> treeWidth - wordWidth*d.id)
		.attr('y', treeHeight-wordHeight)
		.on 'mouseover', (d) ->
			svg.selectAll('.form, .deprel, .edge, .arrow').classed('active', false)
			svg.selectAll('.tag').attr('opacity', 0)
			svg.selectAll(".w#{d.id}").classed('active', true)
			svg.select(".tag.w#{d.id}").attr('opacity', 1)
		.on 'mouseout', (d) ->
			svg.selectAll('.form, .deprel, .edge, .arrow').classed('active', false)
			svg.selectAll('.tag').attr('opacity', 0)
		.attr('text-anchor', 'middle')

	tags = svg.selectAll('.tag').data(data).enter()
		.append('text')
		.text((d) -> d.tag)
		.attr('class', (d) -> "tag w#{d.id}")
		.attr('x', (d) -> treeWidth - wordWidth*d.id)
		.attr('y', treeHeight)
		.attr('opacity', 0)
		.attr('text-anchor', 'middle')
		.attr('font-size', '90%')

	edges = svg.selectAll('.edge').data(data).enter()
		.append('path')
		.filter((d) -> d.id)
		.attr('class', (d) -> "edge w#{d.id} w#{d.head}")
		.attr('d', (d) -> "M#{d.left},#{d.bottom} C#{d.mid-d.diff},#{d.top} #{d.mid+d.diff},#{d.top} #{d.right},#{d.bottom}")
		.attr('fill', 'none')
		.attr('stroke', 'black')
		.attr('stroke-width', '1.5')

	dependencies = svg.selectAll('.deprel').data(data).enter()
		.append('text')
		.filter((d) -> d.id)
		.text((d) -> d.deprel)
		.attr('class', (d) -> "deprel w#{d.id} w#{d.head}")
		.attr('x', (d) -> d.mid)
		.attr('y', (d) -> d.arrow - 7)
		.attr('text-anchor', 'middle')
		.attr('font-size', '90%')

	triangle = d3.svg.symbol().type('triangle-up').size(5)
	arrows = svg.selectAll('.arrow').data(data).enter()
		.append('path')
		.filter((d) -> d.id)
		.attr('class', (d) -> "arrow w#{d.id} w#{d.head}")
		.attr('d', triangle)
		.attr('transform', (d) -> "translate(#{d.mid}, #{d.arrow}) rotate(#{if d.id < d.head then '' else '-'}90)")
		.attr('fill', 'none')
		.attr('stroke', 'black')
		.attr('stroke-width', '1.5')


# functions
maximum = (array) -> Math.max 0, Math.max.apply(null, array);

under = (edge1, edge2) ->
	[mi, ma] = if edge1.id < edge1.head then [edge1.id, edge1.head] else [edge1.head, edge1.id]
	edge1.id != edge2.id and edge2.id >= mi and edge2.head >= mi and edge2.id <= ma and edge2.head <= ma

parseConll = (conllData) ->
	data = []
	data.push id: 0, form: 'ریشه', tag: tagDict['root'], level: 0	
	for line in conllData.split('\n').slice(2) when line
		[id, form, _, upos, xpos, _, head, deprel] = line.split('\t')
		if xpos.includes('_')
			[cpos, fpos] = xpos.split('_')
			tag = tagDict[cpos]+' '+tagDict[fpos]
		else
			tag = tagDict[xpos]
		
		data.push id: Number(id), form: form, tag: tag, head: Number(head), deprel: dependencyDict[deprel], level: 1
	data


tagDict =
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
'PUNCT': 'نشانه سجاوندی',
'SCONJ': 'حرف ربط وابسته‌ساز',
'SYM': 'نماد',
'VERB': 'فعل',
'X': 'سایر'

dependencyDict = 
'acl': 'بندِ نام‌آمیخته',
'acl:relcl': 'توصیف‌گر بند موصولی',
'advcl': 'توصیف‌گر بند قیدی',
'advmod': 'توصیف‌گر قیدی',
'advmod:emph': 'تأکیدافزای',
'advmod:lmod': 'توصیف‌گر قید مکانی',
'amod': 'توصیف‌گر صفتی',
'appos': 'توصیف‌گر دوسویه',
'aux': 'فعل کمکی',
'aux:pass': 'فعل کمکی مجهول',
'case': 'case marking',
'cc': 'حرف ربط همپایه‌ساز',
'cc:preconj': 'preconjunct',
'ccomp': 'مکملِ بندی',
'clf': 'طبقه‌بند',
'compound': 'ترکیب',
'compound:lvc': 'سازهٔ فعلِ همکرد',
'compound:prt': 'ادات فعل گروهی',
'compound:redup': 'ترکیبات بازتکرار شده',
'compound:svc': 'serial verb compounds',
'conj': 'حرف ربط',
'cop': 'فعل ربطی',
'csubj': 'فاعلِ بندی',
'csubj:outer': 'outer clause clausal subject',
'csubj:pass': 'clausal passive subject',
'dep': 'وابسته نامعلوم',
'det': 'تخصیص‌گر',
'det:numgov': 'کمیت‌نمای ضمیری حاکم بر حالت اسم',
'det:nummod': 'pronominal quantifier agreeing in case with the noun',
'det:poss': 'تخصیص‌گر ملکی',
'discourse': 'عنصر گفتمان',
'dislocated': 'dislocated elements',
'expl': 'پوچ‌واژه',
'expl:impers': 'پوچ‌واژه غیرشخصی',
'expl:pass': 'ضمیر انعکاسی به‌کاررفته در مجهول انعکاسی',
'expl:pv': 'واژه‌بست انعکاسی با یک فعل ذاتاً انعکاسی',
'fixed': 'عبارت چندکلمه‌ای ثابت',
'flat': 'عبارت چندکلمه‌ای تخت',
'flat:foreign': 'واژه بیگانه',
'flat:name': 'اسامی',
'goeswith': 'در کنارِ',
'iobj': 'مفعول غیر مستقیم',
'list': 'فهرست',
'mark': 'نشانگر',
'nmod': 'توصیف‌گر ساخت‌واژه',
'nmod:poss': 'توصیف‌گر ساخت‌واژهٔ مالکیتی',
'nmod:tmod': 'توصیف‌گر زمانی',
'nsubj': 'nominal subject',
'nsubj:outer': 'outer clause nominal subject',
'nsubj:pass': 'passive nominal subject',
'nummod': 'توصیف‌گر عددی',
'nummod:gov': 'توصیف‌گر عددی درباره اسم',
'obj': 'مفعول',
'obl': 'oblique nominal',
'obl:agent': 'توصیف‌گر عامل',
'obl:arg': 'oblique argument',
'obl:lmod': 'توصیف‌گر مکانی',
'obl:tmod': 'توصیف‌گر زمانی',
'orphan': 'بدون جایگاه',
'parataxis': 'همپایگی',
'punct': 'نشانه سجاوندی',
'reparandum': 'ناروانی نادیده‌گرفته شده',
'root': 'ریشه',
'vocative': 'ندایی',
'xcomp': 'open clausal complement'