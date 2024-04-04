// Generated by ssao_gensamples.poca
#ifndef SSAO_SAMPLES_GLSL
#define SSAO_SAMPLES_GLSL
#if NUM_SAMPLES == 16
const int countKernelSamples = 16;
const vec3 kernelSamples[16] = vec3[16](
  vec3(-0.7249891466933509, -0.04272272122724784, 0.17367577340380475),
  vec3(-0.12929094728938428, 0.18179302452873036, 0.4611772505147947),
  vec3(-0.08513634670413565, 0.7676187291205127, 0.325583720641652),
  vec3(0.663444380636299, 0.02707560666878247, 0.03339122008950075),
  vec3(-0.8880657040289935, 0.31083860141962333, 0.4298901418213018),
  vec3(-0.014001679598174365, -0.34769319956650657, 0.08375158504261844),
  vec3(0.5603310586108798, -0.18411540444610994, 0.45061850479599574),
  vec3(-0.31682119062079594, -0.6436859064563117, 0.18710898062789708),
  vec3(0.25559530378452394, -0.3884658833253463, 0.5232075190823635),
  vec3(-0.539320370782472, 0.6287840883113197, 0.2715117104436863),
  vec3(0.26825492177566795, 0.11079527867313774, 0.2689702682337364),
  vec3(-0.4406576271633768, -0.5671848033814325, 0.04801977169520911),
  vec3(0.11328854663347486, -0.27861235733156975, 0.33813541482456777),
  vec3(0.399455871720153, 0.6823682627277475, 0.12097335760465176),
  vec3(0.8215723706353841, 0.22283315329171624, 0.21331935045223013),
  vec3(-0.07961402408518768, -0.1931373343365287, 0.20903954459021976)
);
#elif NUM_SAMPLES == 32
const int countKernelSamples = 32;
const vec3 kernelSamples[32] = vec3[32](
  vec3(-0.6809720820254094, -0.08591360705772068, 0.17270837931603356),
  vec3(-0.09393044352006216, 0.1434799050721074, 0.4622804612734201),
  vec3(-0.04280665820109259, 0.7144682063017123, 0.32212700726293186),
  vec3(0.7365394833337583, -0.01563819086501558, 0.03502954753763493),
  vec3(-0.8330049228123659, 0.25865090243215566, 0.42487721572855436),
  vec3(0.019240070915080284, -0.40223989794252446, 0.08800634790333195),
  vec3(0.6307050803195469, -0.23916969615499203, 0.4733237947983846),
  vec3(-0.2867021908070803, -0.7120491855093326, 0.19386054223616161),
  vec3(0.3094211803055248, -0.4523863950426083, 0.5489379275564257),
  vec3(-0.4872173371577087, 0.5713521991472658, 0.26624553562833586),
  vec3(0.3113469647983118, 0.0772956021600652, 0.2778720339896669),
  vec3(-0.41234270464912337, -0.627637420513608, 0.049383142133027726),
  vec3(0.15486531340525153, -0.33141324069495903, 0.3547352071898524),
  vec3(0.44453616792709444, 0.6432759691136495, 0.12204387354230221),
  vec3(0.8980948006674104, 0.18352972064364825, 0.22170111650761243),
  vec3(-0.05022695741076336, -0.2344475105888303, 0.2160571349250746),
  vec3(0.5485349548994346, -0.048786816442344894, 0.6573528918225497),
  vec3(0.000999486385938502, 0.17725876484845435, 0.046632036822342814),
  vec3(0.6401110086345183, 0.5358789263230486, 0.4521519460898832),
  vec3(-0.7228906812399724, -0.22837156439834155, 0.13510785681102921),
  vec3(-0.10817943907615626, 0.021244137813359657, 0.40731950147141904),
  vec3(-0.28974725386379047, -0.394226910648177, 0.19482653843065534),
  vec3(0.245427265025145, -0.17807833684727545, 0.5339683434876604),
  vec3(-0.4111038351711394, 0.08133483166910507, 0.005892614603300982),
  vec3(0.08044746188291284, 0.2936105043208719, 0.30240315302064474),
  vec3(0.30217287933242526, -0.3136333315742313, 0.06568401373971625),
  vec3(-0.6287916678381176, -0.1197222198204873, 0.43446252666520246),
  vec3(-0.03597437627864464, 0.13736079572223378, 0.8065137465881614),
  vec3(0.1798074778117941, 0.9928890217925673, 0.1654188275873508),
  vec3(0.025119282769137326, 0.35246460297718957, 0.19241220635291942),
  vec3(-0.2723503806552118, 0.20889404783744203, 0.6510911738104735),
  vec3(-0.0791949693372522, -0.7682962371032197, 0.021357921904039547)
);
#elif NUM_SAMPLES == 64
const int countKernelSamples = 64;
const vec3 kernelSamples[64] = vec3[64](
  vec3(-0.7217256363654584, -0.12161551378182685, 0.18002048270658572),
  vec3(-0.10689155680273604, 0.11910382072596759, 0.47451308032240297),
  vec3(-0.05526867757196581, 0.690205965114912, 0.3257198426270702),
  vec3(0.7419372820493717, -0.04793292596817705, 0.03585088895582365),
  vec3(-0.8732432714248539, 0.23152951216517562, 0.4386653147238076),
  vec3(0.01003465222694878, -0.45125173249295175, 0.09270826421792502),
  vec3(0.6381477366294, -0.2801558525576221, 0.4882427882716581),
  vec3(-0.3147793304080481, -0.7843602875940904, 0.2043712407509257),
  vec3(0.3098608401929877, -0.5040477812896929, 0.5715203628409145),
  vec3(-0.509296001394706, 0.5502923947571797, 0.2716673393339955),
  vec3(0.30794444981848684, 0.05204875455952639, 0.28375688361566215),
  vec3(-0.4471504319549538, -0.6949971994650478, 0.05207658157191136),
  vec3(0.15094126007740674, -0.3749757495926827, 0.37039167660417505),
  vec3(0.43617165035537475, 0.6162849019554556, 0.12303740262209173),
  vec3(0.9026414038245217, 0.15239254225345983, 0.22600887953148663),
  vec3(-0.06224942911520573, -0.2715478667651791, 0.22642291899482792),
  vec3(0.5509902008481998, -0.08391221169700679, 0.675351750913985),
  vec3(-0.007843741905260349, 0.15956346767123547, 0.048258147999802006),
  vec3(0.6359574969061332, 0.5085795314327541, 0.45830296369225787),
  vec3(-0.7683305804503288, -0.2719520132130799, 0.14129918565807187),
  vec3(-0.12181613365461363, -0.005207234063772445, 0.42065786397799565),
  vec3(-0.31626128560343736, -0.4448708297578699, 0.20528220925593343),
  vec3(0.2426772826443903, -0.2146548709164734, 0.5525593946218348),
  vec3(-0.43585511584848696, 0.05705860443959778, 0.006102560217578821),
  vec3(0.07162940663345668, 0.27098880473478376, 0.306682899487932),
  vec3(0.304628189327661, -0.35458915488577836, 0.06845760736244552),
  vec3(-0.6672555684497462, -0.15774245202784096, 0.45255168874520674),
  vec3(-0.04934987789765957, 0.10794885401933409, 0.8291125296170179),
  vec3(0.16828848901953616, 0.9665627019942528, 0.16692991406490024),
  vec3(0.015637022140997738, 0.3301280820169708, 0.19454957466943765),
  vec3(-0.29192502447977253, 0.18271588122150315, 0.6693962302116154),
  vec3(-0.0959232560270133, -0.843439750753086, 0.022517712871428112),
  vec3(0.5392326435676047, -0.5858714547410218, 0.4050724464401548),
  vec3(-0.24721228456669456, 0.8049905056964756, 0.49761204586259444),
  vec3(0.5151649926928276, -0.0008085966344398508, 0.1484571659426013),
  vec3(-0.4164914759483354, 0.25090594359355595, 0.5146569868606713),
  vec3(0.37610161173622597, -0.1886050979260654, 0.1558541406234813),
  vec3(-0.5688678401347926, 0.036486119327419, 0.5527791686705058),
  vec3(0.24609328849962261, -0.7126862047883255, 0.25992210249441383),
  vec3(0.0979603432312316, -0.11122583017701643, 0.029250801752296645),
  vec3(0.7738878649010387, 0.11584033698487071, 0.42274016532048136),
  vec3(-0.003179462021056719, -0.6309517241611508, 0.479086424472076),
  vec3(0.6575718869074358, 0.18632773473656247, 0.26685733029541164),
  vec3(-0.35702421726678135, 0.4723725355370714, 0.6677444936965161),
  vec3(-0.264469785217961, -0.2495607061969274, 0.2941649435326161),
  vec3(0.29465125779573953, -0.0325523509264001, 0.7048201398890042),
  vec3(0.540479945817086, 0.8099338961143983, 0.058391012878075896),
  vec3(-0.1857313650041172, 0.2022245242032323, 0.09688635928803127),
  vec3(0.37050590607686973, 0.5340071803130538, 0.49966686288597506),
  vec3(0.11868794842542825, 0.030504423644413938, 0.15718334028391173),
  vec3(-0.5818405356484889, -0.44282174121932866, 0.2878079434994707),
  vec3(0.024982464168500775, -0.16902880746778656, 0.6067133463356875),
  vec3(-0.658447594904113, 0.11017296219755279, 0.06509393999115375),
  vec3(-0.07450575311224662, 0.3273183133550384, 0.37662150621427454),
  vec3(-0.23923307392153786, -0.11044030995994489, 0.9436728629122773),
  vec3(-0.13208366282906453, 0.39327403030680846, 0.26026759341009714),
  vec3(0.6287339687437867, -0.2755226475326509, 0.009769348049716214),
  vec3(-0.2961373079307771, -0.022880977602217252, 0.3119922359473973),
  vec3(0.257601328346067, 0.23820819693830683, 0.756128967976951),
  vec3(-0.27267791981908807, -0.7917226428995988, 0.08530010040212038),
  vec3(0.3370635536084081, -0.503866606739541, 0.4413569564389211),
  vec3(-0.4503860937367272, 0.5102855033447784, 0.15008185926165996),
  vec3(-0.5782230436757411, 0.29455911466356854, 0.23341777928361185),
  vec3(0.004485232691286892, 0.5871661197864392, 0.6289202007742755)
);
#endif
#endif
