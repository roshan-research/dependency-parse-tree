
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

dependencyDict = 
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
'xcomp': 'open clausal complement',
