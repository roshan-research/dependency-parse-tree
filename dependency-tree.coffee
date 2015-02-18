
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
		item.right = treeWidth -  item.parent * wordWidth
		item.mid = (item.right+item.left)/2
		item.diff = (item.right-item.left)/4
		item.arrow = item.top + (item.bottom-item.top)*.25

	# draw svg
	svg.selectAll('text, path').remove()
	svg.attr('xmlns', 'http://www.w3.org/2000/svg')
	svg.attr('width', treeWidth + 2*wordWidth/3).attr('height', treeHeight + wordHeight/2)

	words = svg.selectAll('.word').data(data).enter()
		.append('text')
		.text((d) -> d.word)
		.attr('class', (d) -> "word w#{d.id}")
		.attr('x', (d) -> treeWidth - wordWidth*d.id)
		.attr('y', treeHeight-wordHeight)
		.on 'mouseover', (d) ->
			svg.selectAll('.word, .dependency, .edge, .arrow').classed('active', false)
			svg.selectAll('.tag').attr('opacity', 0)
			svg.selectAll(".w#{d.id}").classed('active', true)
			svg.select(".tag.w#{d.id}").attr('opacity', 1)
		.on 'mouseout', (d) ->
			svg.selectAll('.word, .dependency, .edge, .arrow').classed('active', false)
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
		.attr('class', (d) -> "edge w#{d.id} w#{d.parent}")
		.attr('d', (d) -> "M#{d.left},#{d.bottom} C#{d.mid-d.diff},#{d.top} #{d.mid+d.diff},#{d.top} #{d.right},#{d.bottom}")
		.attr('fill', 'none')
		.attr('stroke', 'black')
		.attr('stroke-width', '1.5')

	dependencies = svg.selectAll('.dependency').data(data).enter()
		.append('text')
		.filter((d) -> d.id)
		.text((d) -> d.dependency)
		.attr('class', (d) -> "dependency w#{d.id} w#{d.parent}")
		.attr('x', (d) -> d.mid)
		.attr('y', (d) -> d.arrow - 7)
		.attr('text-anchor', 'middle')
		.attr('font-size', '90%')

	triangle = d3.svg.symbol().type('triangle-up').size(5)
	arrows = svg.selectAll('.arrow').data(data).enter()
		.append('path')
		.filter((d) -> d.id)
		.attr('class', (d) -> "arrow w#{d.id} w#{d.parent}")
		.attr('d', triangle)
		.attr('transform', (d) -> "translate(#{d.mid}, #{d.arrow}) rotate(#{if d.id < d.parent then '' else '-'}90)")
		.attr('fill', 'none')
		.attr('stroke', 'black')
		.attr('stroke-width', '1.5')


# functions
maximum = (array) -> Math.max 0, Math.max.apply(null, array);

under = (edge1, edge2) ->
	[mi, ma] = if edge1.id < edge1.parent then [edge1.id, edge1.parent] else [edge1.parent, edge1.id]
	edge1.id != edge2.id and edge2.id >= mi and edge2.parent >= mi and edge2.id <= ma and edge2.parent <= ma

parseConll = (conllData) ->
	data = []
	data.push id: 0, word: 'ریشه', tag: tagDict['ROOT'], level: 0
	for line in conllData.split('\n') when line
		[id, word, _, cpos, fpos, _, parent, dependency] = line.split('\t')
		tag = if cpos != fpos then tagDict[cpos]+' '+tagDict[fpos] else tagDict[cpos]
		data.push id: Number(id), word: word, tag: tag, parent: Number(parent), dependency: dependencyDict[dependency], level: 1
	data


# dictionary
dependencyDict =
	'': '', 'NE': 'اسم‌یار', 'PART': 'افزودۀ پرسشی فعل', 'APP': 'بدل', 'NCL': 'بند اسم', 'AJUCL': 'بند افزودۀ فعل', 'PARCL': 'بند فعل وصفی', 'TAM': 'تمییز', 'NPRT': 'جزء اسمی', 'LVP': 'جزء همکرد', 'NPP': 'حرف اضافه اسم', 'VPRT': 'حرف اضافه فعلی', 'COMPPP': 'حرف اضافۀ تفضیلی', 'ROOT': 'ریشه جمله', 'NPOSTMOD': 'صفت پسین اسم', 'NPREMOD': 'صفت پیشین اسم', 'PUNC': 'علائم نگارشی', 'SBJ': 'فاعل', 'NVE': 'فعل‌یار', 'ENC': 'فعل‏یار پی‏بستی', 'ADV': 'قید', 'NADV': 'قید اسم', 'PRD': 'گزاره', 'ACL': 'متمم بندی صفت', 'VCL': 'متمم بندی فعل', 'AJPP': 'متمم حرف اضافه‌ای صفت', 'ADVC': 'متمم قیدی فعل', 'NEZ': 'متمم نشانۀ اضافه‌ای صفت', 'PROG': 'مستمرساز', 'MOS': 'مسند', 'MOZ': 'مضافٌ‌الیه', 'OBJ': 'مفعول', 'VPP': 'مفعول حرف اضافه‌ای', 'OBJ2': 'مفعول دوم', 'MESU': 'ممیز', 'AJCONJ': 'هم‌پایه صفت', 'PCONJ': 'هم‌پایۀ حرف اضافه', 'NCONJ': 'هم‏پایه اسم', 'VCONJ': 'هم‏پایه فعل', 'AVCONJ': 'هم‏پایه قید', 'POSDEP': 'وابسته پسین', 'PREDEP': 'وابسته پیشین', 'APOSTMOD': 'وابستۀ پسین صفت', 'APREMOD': 'وابستۀ پیشین صفت'

tagDict =
	'': '', '1': 'اول', '2': 'دوم', '3': 'سوم', 'ACT': 'معلوم', 'ADJ': 'صفت', 'ADR': 'نقش نمای ندا', 'ADV': 'قید', 'AJCM': 'تفضیلی', 'AJP': 'مطلق', 'AJSUP': 'عالی', 'AMBAJ': 'صفت مبهم', 'ANM': 'جاندار', 'AVCM': 'تفضیلی', 'AVP': 'مطلق', 'AY': 'آینده اخباری', 'CL': 'سببی', 'COM': 'تفضیلی', 'CONJ': 'نقش نمای همپایگی', 'CREFX': 'بازتابی مشترک', 'DEMAJ': 'صفت اشاره', 'DEMON': 'اشاره', 'DET': 'حرف تعریف', 'EXAJ': 'صفت تعجبی', 'GB': 'گذشته بعید اخباری', 'GBEL': 'گذشته بعید التزامی', 'GBES': 'گذشته بعید استمراری اخباری', 'GBESE': 'گذشته بعید استمراری التزامی', 'GEL': 'گذشته التزامی', 'GES': 'گذشته استمراری اخباری', 'GESEL': 'گذشته استمراری التزامی', 'GN': 'گذشته نقلی اخباری', 'GNES': 'گذشته نقلی استمراری اخباری', 'GS': 'گذشته ساده اخباری', 'H': 'حال اخباری', 'HA': 'حال امری', 'HEL': 'حال التزامی', 'IANM': 'بی جان', 'IDEN': 'شاخص', 'INTG': 'پرسشی', 'ISO': 'واژه تنها', 'JOPER': 'شخصی پیوسته', 'MODE': 'وجه', 'MODL': 'وجهی', 'N': 'اسم', 'NUM': 'شمار', 'NXT': 'چسبیدگی از چپ', 'PART': 'جزء دستوری', 'PASS': 'مجهول', 'PERS': 'شخص', 'PLUR': 'جمع', 'POSADR': 'پسین', 'POSNUM': 'صفت شمارشی پسین', 'POST': 'مطلق', 'POSTP': 'حرف اضافه پسین', 'PR': 'ضمیر', 'PRADR': 'پیشین', 'PREM': 'پیش توصیفگر', 'PRENUM': 'صفت شمارشی پیشین', 'PREP': 'حرف اضافه پیشین', 'PRV': 'چسبیدگی از راست', 'PSUS': 'شبه جمله', 'PUNC': 'علامت نگارشی', 'QUAJ': 'صفت پرسشی', 'RECPR': 'متقابل', 'SADV': 'مختص', 'SEPER': 'شخصی جدا', 'SING': 'مفرد', 'SUBR': 'نقش نمای وابستگی', 'SUP': 'عالی', 'UCREFX': 'بازتابی غیرمشترک', 'V': 'فعل', 'ROOT': ''
